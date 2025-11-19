// RUN: %clang_cc1 -std=c++26 %s -verify -Wno-unused-value

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
  int z = 3;
  int s = 4;
  int b = 5;
  State huge{6};

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
    [&, &x] {};          // expected-error{{'&' cannot precede a capture when}}
    [&, &x] {};          // expected-error{{'&' cannot precede a capture when}}
    [const &, &x] {};    // expected-error{{'&' cannot precede a capture when}}
    [mutable &, &x] {};  // expected-error{{'&' cannot precede a capture when}}

    // TODO: More checks
  }
  { // More test cases

    [&, mutable & y, const & z] {
      x += 1; // OK
      y += 1; // OK
      z += 1; // expected-error{{}}
    };
    [mutable &, mutable & y, const & z] {
      x += 1; // OK
      y += 1; // OK
      z += 1; // expected-error{{}}
    };
    [const &, mutable & y, const & z] { 
      x += 1; // expected-error{{}}
      y += 1; // OK
      z += 1; // expected-error{{}}
    };
  }
}
