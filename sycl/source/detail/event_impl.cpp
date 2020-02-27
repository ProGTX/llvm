//==---------------- event_impl.cpp - SYCL event ---------------------------==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include <CL/sycl/context.hpp>
#include <detail/event_impl.hpp>
#include <detail/event_info.hpp>
#include <pi/plugin.hpp>
#include <detail/queue_impl.hpp>
#include <detail/scheduler/scheduler.hpp>

#include "detail/config.hpp"

#include <chrono>

#ifdef XPTI_ENABLE_INSTRUMENTATION
#include "xpti_trace_framework.hpp"
#include <atomic>
#include <sstream>
#endif

__SYCL_INLINE_NAMESPACE(cl) {
namespace sycl {
namespace detail {
#ifdef XPTI_ENABLE_INSTRUMENTATION
extern xpti::trace_event_data_t *GSYCLGraphEvent;
#endif

// Threat all devices that don't support interoperability as host devices to
// avoid attempts to call method get on such events.
bool event_impl::is_host() const { return MHostEvent || !MOpenCLInterop; }

cl_event event_impl::get() const {
  if (MOpenCLInterop) {
    getPlugin().call<PiApiKind::piEventRetain>(MEvent);
    return pi::cast<cl_event>(MEvent);
  }
  throw invalid_object_error(
      "This instance of event doesn't support OpenCL interoperability.",
      PI_INVALID_EVENT);
}

event_impl::~event_impl() {
  if (MEvent)
    getPlugin().call<PiApiKind::piEventRelease>(MEvent);
}

void event_impl::waitInternal() const {
  if (!MHostEvent) {
    getPlugin().call<PiApiKind::piEventsWait>(1, &MEvent);
  }
  // Waiting of host events is NOP so far as all operations on host device
  // are blocking.
}

const RT::PiEvent &event_impl::getHandleRef() const { return MEvent; }
RT::PiEvent &event_impl::getHandleRef() { return MEvent; }

const ContextImplPtr &event_impl::getContextImpl() { return MContext; }

const plugin &event_impl::getPlugin() const { return MContext->getPlugin(); }

void event_impl::setContextImpl(const ContextImplPtr &Context) {
  MHostEvent = Context->is_host();
  MOpenCLInterop = !MHostEvent;
  MContext = Context;
}

event_impl::event_impl(RT::PiEvent Event, const context &SyclContext)
    : MEvent(Event), MContext(detail::getSyclObjImpl(SyclContext)),
      MOpenCLInterop(true), MHostEvent(false) {

  if (MContext->is_host()) {
    throw cl::sycl::invalid_parameter_error(
        "The syclContext must match the OpenCL context associated with the "
        "clEvent.",
        PI_INVALID_CONTEXT);
  }

  RT::PiContext TempContext;
  getPlugin().call<PiApiKind::piEventGetInfo>(MEvent, PI_EVENT_INFO_CONTEXT,
                                              sizeof(RT::PiContext),
                                              &TempContext, nullptr);
  if (MContext->getHandleRef() != TempContext) {
    throw cl::sycl::invalid_parameter_error(
        "The syclContext must match the OpenCL context associated with the "
        "clEvent.",
        PI_INVALID_CONTEXT);
  }

  getPlugin().call<PiApiKind::piEventRetain>(MEvent);
}

event_impl::event_impl(QueueImplPtr Queue) : MQueue(Queue) {
  if (Queue->is_host() &&
      Queue->has_property<property::queue::enable_profiling>()) {
    MHostProfilingInfo.reset(new HostProfilingInfo());
    if (!MHostProfilingInfo)
      throw runtime_error("Out of host memory", PI_OUT_OF_HOST_MEMORY);
  }
}

void *event_impl::instrumentationProlog(string_class &Name, int32_t StreamID,
                                        uint64_t &IId) const {
  void *TraceEvent = nullptr;
#ifdef XPTI_ENABLE_INSTRUMENTATION
  if (!xptiTraceEnabled())
    return TraceEvent;
  // Use a thread-safe counter to get a unique instance ID for the wait() on the
  // event
  static std::atomic<uint64_t> InstanceID = {1};
  xpti::trace_event_data_t *WaitEvent = nullptr;

  // Create a string with the event address so it
  // can be associated with other debug data
  xpti::utils::StringHelper SH;
  Name = SH.nameWithAddress<RT::PiEvent>("event.wait", MEvent);

  // We can emit the wait associated with the graph if the
  // event does not have a command object or associated with
  // the command object, if it exists
  if (MCommand) {
    Command *Cmd = (Command *)MCommand;
    WaitEvent = Cmd->MTraceEvent ? static_cast<xpti_td *>(Cmd->MTraceEvent)
                                 : GSYCLGraphEvent;
  } else
    WaitEvent = GSYCLGraphEvent;

  // Record the current instance ID for use by Epilog
  IId = InstanceID++;
  xptiNotifySubscribers(StreamID, xpti::trace_wait_begin, nullptr, WaitEvent,
                        IId, static_cast<const void *>(Name.c_str()));
  TraceEvent = (void *)WaitEvent;
#endif
  return TraceEvent;
}

void event_impl::instrumentationEpilog(void *TelemetryEvent,
                                       const string_class &Name,
                                       int32_t StreamID, uint64_t IId) const {
#ifdef XPTI_ENABLE_INSTRUMENTATION
  if (!(xptiTraceEnabled() && TelemetryEvent))
    return;
  // Close the wait() scope
  xpti::trace_event_data_t *TraceEvent =
      (xpti::trace_event_data_t *)TelemetryEvent;
  xptiNotifySubscribers(StreamID, xpti::trace_wait_end, nullptr, TraceEvent,
                        IId, static_cast<const void *>(Name.c_str()));
#endif
}

void event_impl::wait(
    std::shared_ptr<cl::sycl::detail::event_impl> Self) const {
#ifdef XPTI_ENABLE_INSTRUMENTATION
  void *TelemetryEvent = nullptr;
  uint64_t IId;
  std::string Name;
  int32_t StreamID = xptiRegisterStream(SYCL_STREAM_NAME);
  TelemetryEvent = instrumentationProlog(Name, StreamID, IId);
#endif

  if (MEvent)
    // presence of MEvent means the command has been enqueued, so no need to
    // go via the slow path event waiting in the scheduler
    waitInternal();
  else if (MCommand)
    detail::Scheduler::getInstance().waitForEvent(Self);
  if (MCommand && !SYCLConfig<SYCL_DISABLE_EXECUTION_GRAPH_CLEANUP>::get())
    detail::Scheduler::getInstance().cleanupFinishedCommands(std::move(Self));

#ifdef XPTI_ENABLE_INSTRUMENTATION
  instrumentationEpilog(TelemetryEvent, Name, StreamID, IId);
#endif
}

void event_impl::wait_and_throw(
    std::shared_ptr<cl::sycl::detail::event_impl> Self) {
  wait(Self);
  for (auto &EventImpl :
       detail::Scheduler::getInstance().getWaitList(std::move(Self))) {
    Command *Cmd = (Command *)EventImpl->getCommand();
    if (Cmd)
      Cmd->getQueue()->throw_asynchronous();
  }
  QueueImplPtr Queue = MQueue.lock();
  if (Queue)
    Queue->throw_asynchronous();
}

template <>
cl_ulong
event_impl::get_profiling_info<info::event_profiling::command_submit>() const {
  if (!MHostEvent) {
    return get_event_profiling_info<info::event_profiling::command_submit>::get(
        this->getHandleRef(), this->getPlugin());
  }
  if (!MHostProfilingInfo)
    throw invalid_object_error("Profiling info is not available.",
                               PI_PROFILING_INFO_NOT_AVAILABLE);
  return MHostProfilingInfo->getStartTime();
}

template <>
cl_ulong
event_impl::get_profiling_info<info::event_profiling::command_start>() const {
  if (!MHostEvent) {
    return get_event_profiling_info<info::event_profiling::command_start>::get(
        this->getHandleRef(), this->getPlugin());
  }
  if (!MHostProfilingInfo)
    throw invalid_object_error("Profiling info is not available.",
                               PI_PROFILING_INFO_NOT_AVAILABLE);
  return MHostProfilingInfo->getStartTime();
}

template <>
cl_ulong
event_impl::get_profiling_info<info::event_profiling::command_end>() const {
  if (!MHostEvent) {
    return get_event_profiling_info<info::event_profiling::command_end>::get(
        this->getHandleRef(), this->getPlugin());
  }
  if (!MHostProfilingInfo)
    throw invalid_object_error("Profiling info is not available.",
                               PI_PROFILING_INFO_NOT_AVAILABLE);
  return MHostProfilingInfo->getEndTime();
}

template <> cl_uint event_impl::get_info<info::event::reference_count>() const {
  if (!MHostEvent) {
    return get_event_info<info::event::reference_count>::get(
        this->getHandleRef(), this->getPlugin());
  }
  return 0;
}

template <>
info::event_command_status
event_impl::get_info<info::event::command_execution_status>() const {
  if (!MHostEvent) {
    return get_event_info<info::event::command_execution_status>::get(
        this->getHandleRef(), this->getPlugin());
  }
  return info::event_command_status::complete;
}

static uint64_t getTimestamp() {
  auto TimeStamp = std::chrono::high_resolution_clock::now().time_since_epoch();
  return std::chrono::duration_cast<std::chrono::nanoseconds>(TimeStamp)
      .count();
}

void HostProfilingInfo::start() { StartTime = getTimestamp(); }

void HostProfilingInfo::end() { EndTime = getTimestamp(); }

} // namespace detail
} // namespace sycl
} // __SYCL_INLINE_NAMESPACE(cl)
