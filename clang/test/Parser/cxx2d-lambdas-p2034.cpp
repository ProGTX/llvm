// RUN: %clang_cc1 -std=c++26 %s -verify

template <class T> struct remove_reference {
  typedef T type;
};
template <class T> struct remove_reference<T &> {
  typedef T type;
};
template <class T> struct remove_reference<T &&> {
  typedef T type;
};
template <class T>
constexpr typename remove_reference<T>::type &&move(T &&t) noexcept {
  return static_cast<typename remove_reference<T>::type &&>(t);
}

struct State {
  int value;
};
template <class... Args> auto delay_invoke_foo(Args... args, State s) {
  // Valid code proposed by P2034R5
  return [s, mutable... args = move(args)] { return foo(s, move(args)...); };
}

int main() {
  int x = 1;
  int y = 2;
  int s = 3;
  int b = 4;
  State huge{5};

  { // Valid code proposed by P2034R5

    auto a = [mutable x, y]() {};

    auto f0 = [s, mutable b] {
      // ...
    };

    auto f1 = [s, const b] mutable {
      // ...
    };

    auto f21 = [s, const & huge] mutable {
      // ...
    };

    auto f22 = [const & ] {
      // ... const context
    };

    auto f3 = [x]() const {};

    auto f4 = [const x]() {};

    auto f5 = [mutable x]() mutable {};
  }
  { // Code not mentioned by P2034R5, but should be valid

    // TODO
  }
  { // Invalid code

    // TODO: Better errors
    [mutable = ] {};     // expected-error{{}}
    [const = ] {};       // expected-error{{}}
    [] const mutable {}; // expected-error{{}}
    [] mutable const {}; // expected-error{{}}
    [] static const {};  // expected-error{{lambda cannot be both}}

    // TODO: More checks
  }
}
