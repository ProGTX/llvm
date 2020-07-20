; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -ppc-asm-full-reg-names -verify-machineinstrs \
; RUN:   -mtriple=powerpc64le-linux-gnu < %s | FileCheck \
; RUN:   -check-prefix=CHECK-LE %s
; RUN: llc -ppc-asm-full-reg-names -verify-machineinstrs \
; RUN:   -mtriple=powerpc64le-linux-gnu -mcpu=pwr9 < %s | FileCheck \
; RUN:   -check-prefix=CHECK-P9-LE %s
; RUN: llc -ppc-asm-full-reg-names -verify-machineinstrs \
; RUN:   -mtriple=powerpc64-linux-gnu < %s | FileCheck \
; RUN:   -check-prefix=CHECK-BE %s
; RUN: llc -ppc-asm-full-reg-names -verify-machineinstrs \
; RUN:   -mtriple=powerpc-linux-gnu < %s | FileCheck \
; RUN:   -check-prefix=CHECK-32 %s

define i32 @foo(i32 %n) local_unnamed_addr #0 "stack-probe-size"="32768" nounwind {
; CHECK-LE-LABEL: foo:
; CHECK-LE:       # %bb.0:
; CHECK-LE-NEXT:    std r31, -8(r1)
; CHECK-LE-NEXT:    stdu r1, -48(r1)
; CHECK-LE-NEXT:    rldic r3, r3, 2, 30
; CHECK-LE-NEXT:    li r6, -32768
; CHECK-LE-NEXT:    mr r31, r1
; CHECK-LE-NEXT:    addi r3, r3, 15
; CHECK-LE-NEXT:    addi r4, r31, 48
; CHECK-LE-NEXT:    rldicl r3, r3, 60, 4
; CHECK-LE-NEXT:    rldicl r3, r3, 4, 29
; CHECK-LE-NEXT:    neg r5, r3
; CHECK-LE-NEXT:    divd r7, r5, r6
; CHECK-LE-NEXT:    add r3, r1, r5
; CHECK-LE-NEXT:    mulld r6, r7, r6
; CHECK-LE-NEXT:    sub r5, r5, r6
; CHECK-LE-NEXT:    stdux r4, r1, r5
; CHECK-LE-NEXT:    cmpd r1, r3
; CHECK-LE-NEXT:    beq cr0, .LBB0_2
; CHECK-LE-NEXT:  .LBB0_1:
; CHECK-LE-NEXT:    stdu r4, -32768(r1)
; CHECK-LE-NEXT:    cmpd r1, r3
; CHECK-LE-NEXT:    bne cr0, .LBB0_1
; CHECK-LE-NEXT:  .LBB0_2:
; CHECK-LE-NEXT:    li r4, 1
; CHECK-LE-NEXT:    addi r3, r1, 32
; CHECK-LE-NEXT:    stw r4, 4792(r3)
; CHECK-LE-NEXT:    lwz r3, 0(r3)
; CHECK-LE-NEXT:    ld r1, 0(r1)
; CHECK-LE-NEXT:    ld r31, -8(r1)
; CHECK-LE-NEXT:    blr
;
; CHECK-P9-LE-LABEL: foo:
; CHECK-P9-LE:       # %bb.0:
; CHECK-P9-LE-NEXT:    std r31, -8(r1)
; CHECK-P9-LE-NEXT:    stdu r1, -48(r1)
; CHECK-P9-LE-NEXT:    rldic r3, r3, 2, 30
; CHECK-P9-LE-NEXT:    addi r3, r3, 15
; CHECK-P9-LE-NEXT:    li r6, -32768
; CHECK-P9-LE-NEXT:    mr r31, r1
; CHECK-P9-LE-NEXT:    addi r4, r31, 48
; CHECK-P9-LE-NEXT:    rldicl r3, r3, 60, 4
; CHECK-P9-LE-NEXT:    rldicl r3, r3, 4, 29
; CHECK-P9-LE-NEXT:    neg r5, r3
; CHECK-P9-LE-NEXT:    divd r7, r5, r6
; CHECK-P9-LE-NEXT:    add r3, r1, r5
; CHECK-P9-LE-NEXT:    mulld r6, r7, r6
; CHECK-P9-LE-NEXT:    sub r5, r5, r6
; CHECK-P9-LE-NEXT:    stdux r4, r1, r5
; CHECK-P9-LE-NEXT:    cmpd r1, r3
; CHECK-P9-LE-NEXT:    beq cr0, .LBB0_2
; CHECK-P9-LE-NEXT:  .LBB0_1:
; CHECK-P9-LE-NEXT:    stdu r4, -32768(r1)
; CHECK-P9-LE-NEXT:    cmpd r1, r3
; CHECK-P9-LE-NEXT:    bne cr0, .LBB0_1
; CHECK-P9-LE-NEXT:  .LBB0_2:
; CHECK-P9-LE-NEXT:    li r4, 1
; CHECK-P9-LE-NEXT:    addi r3, r1, 32
; CHECK-P9-LE-NEXT:    stw r4, 4792(r3)
; CHECK-P9-LE-NEXT:    lwz r3, 0(r3)
; CHECK-P9-LE-NEXT:    ld r1, 0(r1)
; CHECK-P9-LE-NEXT:    ld r31, -8(r1)
; CHECK-P9-LE-NEXT:    blr
;
; CHECK-BE-LABEL: foo:
; CHECK-BE:       # %bb.0:
; CHECK-BE-NEXT:    std r31, -8(r1)
; CHECK-BE-NEXT:    stdu r1, -64(r1)
; CHECK-BE-NEXT:    rldic r3, r3, 2, 30
; CHECK-BE-NEXT:    li r6, -32768
; CHECK-BE-NEXT:    addi r3, r3, 15
; CHECK-BE-NEXT:    rldicl r3, r3, 60, 4
; CHECK-BE-NEXT:    mr r31, r1
; CHECK-BE-NEXT:    rldicl r3, r3, 4, 29
; CHECK-BE-NEXT:    addi r4, r31, 64
; CHECK-BE-NEXT:    neg r5, r3
; CHECK-BE-NEXT:    divd r7, r5, r6
; CHECK-BE-NEXT:    add r3, r1, r5
; CHECK-BE-NEXT:    mulld r6, r7, r6
; CHECK-BE-NEXT:    sub r5, r5, r6
; CHECK-BE-NEXT:    stdux r4, r1, r5
; CHECK-BE-NEXT:    cmpd r1, r3
; CHECK-BE-NEXT:    beq cr0, .LBB0_2
; CHECK-BE-NEXT:  .LBB0_1:
; CHECK-BE-NEXT:    stdu r4, -32768(r1)
; CHECK-BE-NEXT:    cmpd r1, r3
; CHECK-BE-NEXT:    bne cr0, .LBB0_1
; CHECK-BE-NEXT:  .LBB0_2:
; CHECK-BE-NEXT:    li r4, 1
; CHECK-BE-NEXT:    addi r3, r1, 48
; CHECK-BE-NEXT:    stw r4, 4792(r3)
; CHECK-BE-NEXT:    lwz r3, 0(r3)
; CHECK-BE-NEXT:    ld r1, 0(r1)
; CHECK-BE-NEXT:    ld r31, -8(r1)
; CHECK-BE-NEXT:    blr
;
; CHECK-32-LABEL: foo:
; CHECK-32:       # %bb.0:
; CHECK-32-NEXT:    stwu r1, -32(r1)
; CHECK-32-NEXT:    slwi r3, r3, 2
; CHECK-32-NEXT:    addi r3, r3, 15
; CHECK-32-NEXT:    rlwinm r3, r3, 0, 0, 27
; CHECK-32-NEXT:    neg r5, r3
; CHECK-32-NEXT:    li r6, -32768
; CHECK-32-NEXT:    divw r7, r5, r6
; CHECK-32-NEXT:    stw r31, 28(r1)
; CHECK-32-NEXT:    mr r31, r1
; CHECK-32-NEXT:    addi r4, r31, 32
; CHECK-32-NEXT:    add r3, r1, r5
; CHECK-32-NEXT:    mullw r6, r7, r6
; CHECK-32-NEXT:    sub r5, r5, r6
; CHECK-32-NEXT:    stwux r4, r1, r5
; CHECK-32-NEXT:    cmpw r1, r3
; CHECK-32-NEXT:    beq cr0, .LBB0_2
; CHECK-32-NEXT:  .LBB0_1:
; CHECK-32-NEXT:    stwu r4, -32768(r1)
; CHECK-32-NEXT:    cmpw r1, r3
; CHECK-32-NEXT:    bne cr0, .LBB0_1
; CHECK-32-NEXT:  .LBB0_2:
; CHECK-32-NEXT:    li r4, 1
; CHECK-32-NEXT:    addi r3, r1, 16
; CHECK-32-NEXT:    stw r4, 4792(r3)
; CHECK-32-NEXT:    lwz r3, 0(r3)
; CHECK-32-NEXT:    lwz r31, 0(r1)
; CHECK-32-NEXT:    lwz r0, -4(r31)
; CHECK-32-NEXT:    mr r1, r31
; CHECK-32-NEXT:    mr r31, r0
; CHECK-32-NEXT:    blr
  %a = alloca i32, i32 %n, align 16
  %b = getelementptr inbounds i32, i32* %a, i64 1198
  store volatile i32 1, i32* %b
  %c = load volatile i32, i32* %a
  ret i32 %c
}

define i32 @bar(i32 %n) local_unnamed_addr #0 nounwind {
; CHECK-LE-LABEL: bar:
; CHECK-LE:       # %bb.0:
; CHECK-LE-NEXT:    std r31, -8(r1)
; CHECK-LE-NEXT:    stdu r1, -48(r1)
; CHECK-LE-NEXT:    rldic r4, r3, 2, 30
; CHECK-LE-NEXT:    li r7, -4096
; CHECK-LE-NEXT:    mr r31, r1
; CHECK-LE-NEXT:    addi r4, r4, 15
; CHECK-LE-NEXT:    addi r5, r31, 48
; CHECK-LE-NEXT:    rldicl r4, r4, 60, 4
; CHECK-LE-NEXT:    rldicl r4, r4, 4, 29
; CHECK-LE-NEXT:    neg r6, r4
; CHECK-LE-NEXT:    divd r8, r6, r7
; CHECK-LE-NEXT:    add r4, r1, r6
; CHECK-LE-NEXT:    mulld r7, r8, r7
; CHECK-LE-NEXT:    sub r6, r6, r7
; CHECK-LE-NEXT:    stdux r5, r1, r6
; CHECK-LE-NEXT:    cmpd r1, r4
; CHECK-LE-NEXT:    beq cr0, .LBB1_2
; CHECK-LE-NEXT:  .LBB1_1:
; CHECK-LE-NEXT:    stdu r5, -4096(r1)
; CHECK-LE-NEXT:    cmpd r1, r4
; CHECK-LE-NEXT:    bne cr0, .LBB1_1
; CHECK-LE-NEXT:  .LBB1_2:
; CHECK-LE-NEXT:    extsw r3, r3
; CHECK-LE-NEXT:    li r5, 1
; CHECK-LE-NEXT:    addi r4, r1, 32
; CHECK-LE-NEXT:    sldi r3, r3, 2
; CHECK-LE-NEXT:    add r3, r4, r3
; CHECK-LE-NEXT:    stw r5, 4096(r3)
; CHECK-LE-NEXT:    lwz r3, 0(r4)
; CHECK-LE-NEXT:    ld r1, 0(r1)
; CHECK-LE-NEXT:    ld r31, -8(r1)
; CHECK-LE-NEXT:    blr
;
; CHECK-P9-LE-LABEL: bar:
; CHECK-P9-LE:       # %bb.0:
; CHECK-P9-LE-NEXT:    std r31, -8(r1)
; CHECK-P9-LE-NEXT:    stdu r1, -48(r1)
; CHECK-P9-LE-NEXT:    rldic r4, r3, 2, 30
; CHECK-P9-LE-NEXT:    addi r4, r4, 15
; CHECK-P9-LE-NEXT:    li r7, -4096
; CHECK-P9-LE-NEXT:    mr r31, r1
; CHECK-P9-LE-NEXT:    addi r5, r31, 48
; CHECK-P9-LE-NEXT:    rldicl r4, r4, 60, 4
; CHECK-P9-LE-NEXT:    rldicl r4, r4, 4, 29
; CHECK-P9-LE-NEXT:    neg r6, r4
; CHECK-P9-LE-NEXT:    divd r8, r6, r7
; CHECK-P9-LE-NEXT:    add r4, r1, r6
; CHECK-P9-LE-NEXT:    mulld r7, r8, r7
; CHECK-P9-LE-NEXT:    sub r6, r6, r7
; CHECK-P9-LE-NEXT:    stdux r5, r1, r6
; CHECK-P9-LE-NEXT:    cmpd r1, r4
; CHECK-P9-LE-NEXT:    beq cr0, .LBB1_2
; CHECK-P9-LE-NEXT:  .LBB1_1:
; CHECK-P9-LE-NEXT:    stdu r5, -4096(r1)
; CHECK-P9-LE-NEXT:    cmpd r1, r4
; CHECK-P9-LE-NEXT:    bne cr0, .LBB1_1
; CHECK-P9-LE-NEXT:  .LBB1_2:
; CHECK-P9-LE-NEXT:    extswsli r3, r3, 2
; CHECK-P9-LE-NEXT:    li r5, 1
; CHECK-P9-LE-NEXT:    addi r4, r1, 32
; CHECK-P9-LE-NEXT:    add r3, r4, r3
; CHECK-P9-LE-NEXT:    stw r5, 4096(r3)
; CHECK-P9-LE-NEXT:    lwz r3, 0(r4)
; CHECK-P9-LE-NEXT:    ld r1, 0(r1)
; CHECK-P9-LE-NEXT:    ld r31, -8(r1)
; CHECK-P9-LE-NEXT:    blr
;
; CHECK-BE-LABEL: bar:
; CHECK-BE:       # %bb.0:
; CHECK-BE-NEXT:    std r31, -8(r1)
; CHECK-BE-NEXT:    stdu r1, -64(r1)
; CHECK-BE-NEXT:    rldic r4, r3, 2, 30
; CHECK-BE-NEXT:    li r7, -4096
; CHECK-BE-NEXT:    addi r4, r4, 15
; CHECK-BE-NEXT:    rldicl r4, r4, 60, 4
; CHECK-BE-NEXT:    mr r31, r1
; CHECK-BE-NEXT:    rldicl r4, r4, 4, 29
; CHECK-BE-NEXT:    addi r5, r31, 64
; CHECK-BE-NEXT:    neg r6, r4
; CHECK-BE-NEXT:    divd r8, r6, r7
; CHECK-BE-NEXT:    add r4, r1, r6
; CHECK-BE-NEXT:    mulld r7, r8, r7
; CHECK-BE-NEXT:    sub r6, r6, r7
; CHECK-BE-NEXT:    stdux r5, r1, r6
; CHECK-BE-NEXT:    cmpd r1, r4
; CHECK-BE-NEXT:    beq cr0, .LBB1_2
; CHECK-BE-NEXT:  .LBB1_1:
; CHECK-BE-NEXT:    stdu r5, -4096(r1)
; CHECK-BE-NEXT:    cmpd r1, r4
; CHECK-BE-NEXT:    bne cr0, .LBB1_1
; CHECK-BE-NEXT:  .LBB1_2:
; CHECK-BE-NEXT:    extsw r3, r3
; CHECK-BE-NEXT:    addi r4, r1, 48
; CHECK-BE-NEXT:    sldi r3, r3, 2
; CHECK-BE-NEXT:    li r5, 1
; CHECK-BE-NEXT:    add r3, r4, r3
; CHECK-BE-NEXT:    stw r5, 4096(r3)
; CHECK-BE-NEXT:    lwz r3, 0(r4)
; CHECK-BE-NEXT:    ld r1, 0(r1)
; CHECK-BE-NEXT:    ld r31, -8(r1)
; CHECK-BE-NEXT:    blr
;
; CHECK-32-LABEL: bar:
; CHECK-32:       # %bb.0:
; CHECK-32-NEXT:    stwu r1, -32(r1)
; CHECK-32-NEXT:    slwi r3, r3, 2
; CHECK-32-NEXT:    addi r4, r3, 15
; CHECK-32-NEXT:    rlwinm r4, r4, 0, 0, 27
; CHECK-32-NEXT:    neg r6, r4
; CHECK-32-NEXT:    li r7, -4096
; CHECK-32-NEXT:    divw r8, r6, r7
; CHECK-32-NEXT:    stw r31, 28(r1)
; CHECK-32-NEXT:    mr r31, r1
; CHECK-32-NEXT:    addi r5, r31, 32
; CHECK-32-NEXT:    add r4, r1, r6
; CHECK-32-NEXT:    mullw r7, r8, r7
; CHECK-32-NEXT:    sub r6, r6, r7
; CHECK-32-NEXT:    stwux r5, r1, r6
; CHECK-32-NEXT:    cmpw r1, r4
; CHECK-32-NEXT:    beq cr0, .LBB1_2
; CHECK-32-NEXT:  .LBB1_1:
; CHECK-32-NEXT:    stwu r5, -4096(r1)
; CHECK-32-NEXT:    cmpw r1, r4
; CHECK-32-NEXT:    bne cr0, .LBB1_1
; CHECK-32-NEXT:  .LBB1_2:
; CHECK-32-NEXT:    addi r4, r1, 16
; CHECK-32-NEXT:    li r5, 1
; CHECK-32-NEXT:    add r3, r4, r3
; CHECK-32-NEXT:    stw r5, 4096(r3)
; CHECK-32-NEXT:    lwz r3, 0(r4)
; CHECK-32-NEXT:    lwz r31, 0(r1)
; CHECK-32-NEXT:    lwz r0, -4(r31)
; CHECK-32-NEXT:    mr r1, r31
; CHECK-32-NEXT:    mr r31, r0
; CHECK-32-NEXT:    blr
  %a = alloca i32, i32 %n, align 16
  %i = add i32 %n, 1024
  %b = getelementptr inbounds i32, i32* %a, i32 %i
  store volatile i32 1, i32* %b
  %c = load volatile i32, i32* %a
  ret i32 %c
}

define i32 @f(i32 %n) local_unnamed_addr #0 "stack-probe-size"="65536" nounwind {
; CHECK-LE-LABEL: f:
; CHECK-LE:       # %bb.0:
; CHECK-LE-NEXT:    std r31, -8(r1)
; CHECK-LE-NEXT:    stdu r1, -48(r1)
; CHECK-LE-NEXT:    rldic r3, r3, 2, 30
; CHECK-LE-NEXT:    lis r5, -1
; CHECK-LE-NEXT:    mr r31, r1
; CHECK-LE-NEXT:    addi r3, r3, 15
; CHECK-LE-NEXT:    ori r5, r5, 0
; CHECK-LE-NEXT:    addi r4, r31, 48
; CHECK-LE-NEXT:    rldicl r3, r3, 60, 4
; CHECK-LE-NEXT:    rldicl r3, r3, 4, 29
; CHECK-LE-NEXT:    neg r6, r3
; CHECK-LE-NEXT:    divd r7, r6, r5
; CHECK-LE-NEXT:    add r3, r1, r6
; CHECK-LE-NEXT:    mulld r7, r7, r5
; CHECK-LE-NEXT:    sub r6, r6, r7
; CHECK-LE-NEXT:    stdux r4, r1, r6
; CHECK-LE-NEXT:    cmpd r1, r3
; CHECK-LE-NEXT:    beq cr0, .LBB2_2
; CHECK-LE-NEXT:  .LBB2_1:
; CHECK-LE-NEXT:    stdux r4, r1, r5
; CHECK-LE-NEXT:    cmpd r1, r3
; CHECK-LE-NEXT:    bne cr0, .LBB2_1
; CHECK-LE-NEXT:  .LBB2_2:
; CHECK-LE-NEXT:    li r4, 1
; CHECK-LE-NEXT:    addi r3, r1, 32
; CHECK-LE-NEXT:    stw r4, 4792(r3)
; CHECK-LE-NEXT:    lwz r3, 0(r3)
; CHECK-LE-NEXT:    ld r1, 0(r1)
; CHECK-LE-NEXT:    ld r31, -8(r1)
; CHECK-LE-NEXT:    blr
;
; CHECK-P9-LE-LABEL: f:
; CHECK-P9-LE:       # %bb.0:
; CHECK-P9-LE-NEXT:    std r31, -8(r1)
; CHECK-P9-LE-NEXT:    stdu r1, -48(r1)
; CHECK-P9-LE-NEXT:    rldic r3, r3, 2, 30
; CHECK-P9-LE-NEXT:    addi r3, r3, 15
; CHECK-P9-LE-NEXT:    lis r5, -1
; CHECK-P9-LE-NEXT:    ori r5, r5, 0
; CHECK-P9-LE-NEXT:    mr r31, r1
; CHECK-P9-LE-NEXT:    addi r4, r31, 48
; CHECK-P9-LE-NEXT:    rldicl r3, r3, 60, 4
; CHECK-P9-LE-NEXT:    rldicl r3, r3, 4, 29
; CHECK-P9-LE-NEXT:    neg r6, r3
; CHECK-P9-LE-NEXT:    divd r7, r6, r5
; CHECK-P9-LE-NEXT:    add r3, r1, r6
; CHECK-P9-LE-NEXT:    mulld r7, r7, r5
; CHECK-P9-LE-NEXT:    sub r6, r6, r7
; CHECK-P9-LE-NEXT:    stdux r4, r1, r6
; CHECK-P9-LE-NEXT:    cmpd r1, r3
; CHECK-P9-LE-NEXT:    beq cr0, .LBB2_2
; CHECK-P9-LE-NEXT:  .LBB2_1:
; CHECK-P9-LE-NEXT:    stdux r4, r1, r5
; CHECK-P9-LE-NEXT:    cmpd r1, r3
; CHECK-P9-LE-NEXT:    bne cr0, .LBB2_1
; CHECK-P9-LE-NEXT:  .LBB2_2:
; CHECK-P9-LE-NEXT:    li r4, 1
; CHECK-P9-LE-NEXT:    addi r3, r1, 32
; CHECK-P9-LE-NEXT:    stw r4, 4792(r3)
; CHECK-P9-LE-NEXT:    lwz r3, 0(r3)
; CHECK-P9-LE-NEXT:    ld r1, 0(r1)
; CHECK-P9-LE-NEXT:    ld r31, -8(r1)
; CHECK-P9-LE-NEXT:    blr
;
; CHECK-BE-LABEL: f:
; CHECK-BE:       # %bb.0:
; CHECK-BE-NEXT:    std r31, -8(r1)
; CHECK-BE-NEXT:    stdu r1, -64(r1)
; CHECK-BE-NEXT:    rldic r3, r3, 2, 30
; CHECK-BE-NEXT:    lis r5, -1
; CHECK-BE-NEXT:    addi r3, r3, 15
; CHECK-BE-NEXT:    rldicl r3, r3, 60, 4
; CHECK-BE-NEXT:    ori r5, r5, 0
; CHECK-BE-NEXT:    rldicl r3, r3, 4, 29
; CHECK-BE-NEXT:    mr r31, r1
; CHECK-BE-NEXT:    neg r6, r3
; CHECK-BE-NEXT:    divd r7, r6, r5
; CHECK-BE-NEXT:    addi r4, r31, 64
; CHECK-BE-NEXT:    mulld r7, r7, r5
; CHECK-BE-NEXT:    add r3, r1, r6
; CHECK-BE-NEXT:    sub r6, r6, r7
; CHECK-BE-NEXT:    stdux r4, r1, r6
; CHECK-BE-NEXT:    cmpd r1, r3
; CHECK-BE-NEXT:    beq cr0, .LBB2_2
; CHECK-BE-NEXT:  .LBB2_1:
; CHECK-BE-NEXT:    stdux r4, r1, r5
; CHECK-BE-NEXT:    cmpd r1, r3
; CHECK-BE-NEXT:    bne cr0, .LBB2_1
; CHECK-BE-NEXT:  .LBB2_2:
; CHECK-BE-NEXT:    li r4, 1
; CHECK-BE-NEXT:    addi r3, r1, 48
; CHECK-BE-NEXT:    stw r4, 4792(r3)
; CHECK-BE-NEXT:    lwz r3, 0(r3)
; CHECK-BE-NEXT:    ld r1, 0(r1)
; CHECK-BE-NEXT:    ld r31, -8(r1)
; CHECK-BE-NEXT:    blr
;
; CHECK-32-LABEL: f:
; CHECK-32:       # %bb.0:
; CHECK-32-NEXT:    stwu r1, -32(r1)
; CHECK-32-NEXT:    slwi r3, r3, 2
; CHECK-32-NEXT:    addi r3, r3, 15
; CHECK-32-NEXT:    rlwinm r3, r3, 0, 0, 27
; CHECK-32-NEXT:    lis r5, -1
; CHECK-32-NEXT:    neg r6, r3
; CHECK-32-NEXT:    ori r5, r5, 0
; CHECK-32-NEXT:    divw r7, r6, r5
; CHECK-32-NEXT:    stw r31, 28(r1)
; CHECK-32-NEXT:    mr r31, r1
; CHECK-32-NEXT:    addi r4, r31, 32
; CHECK-32-NEXT:    add r3, r1, r6
; CHECK-32-NEXT:    mullw r7, r7, r5
; CHECK-32-NEXT:    sub r6, r6, r7
; CHECK-32-NEXT:    stwux r4, r1, r6
; CHECK-32-NEXT:    cmpw r1, r3
; CHECK-32-NEXT:    beq cr0, .LBB2_2
; CHECK-32-NEXT:  .LBB2_1:
; CHECK-32-NEXT:    stwux r4, r1, r5
; CHECK-32-NEXT:    cmpw r1, r3
; CHECK-32-NEXT:    bne cr0, .LBB2_1
; CHECK-32-NEXT:  .LBB2_2:
; CHECK-32-NEXT:    li r4, 1
; CHECK-32-NEXT:    addi r3, r1, 16
; CHECK-32-NEXT:    stw r4, 4792(r3)
; CHECK-32-NEXT:    lwz r3, 0(r3)
; CHECK-32-NEXT:    lwz r31, 0(r1)
; CHECK-32-NEXT:    lwz r0, -4(r31)
; CHECK-32-NEXT:    mr r1, r31
; CHECK-32-NEXT:    mr r31, r0
; CHECK-32-NEXT:    blr
  %a = alloca i32, i32 %n, align 16
  %b = getelementptr inbounds i32, i32* %a, i64 1198
  store volatile i32 1, i32* %b
  %c = load volatile i32, i32* %a
  ret i32 %c
}

attributes #0 =  {"probe-stack"="inline-asm"}
