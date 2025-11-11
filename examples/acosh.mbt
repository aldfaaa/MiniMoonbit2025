// acosh(x) function - Inverse hyperbolic cosine
// Ported from math.mbt to test MiniMoonBit compiler
//
// Compiler features tested:
// 1. **External C function calls**: sqrt, log, log1p from C math library
// 2. **Domain checking**: x must be >= 1
// 3. **Mathematical formula**: acosh(x) = log(x + sqrt(x²-1))
// 4. **Special value handling**: NaN for x < 1, infinity detection
// 5. **Multiple algorithm paths**: different algorithms for different ranges

// ============================================
// Extern C functions
// ============================================

extern "C" fn sqrt(x: Double) -> Double = "sqrt";
extern "C" fn log(x: Double) -> Double = "log";
extern "C" fn log1p(x: Double) -> Double = "log1p";

// ============================================
// Helper functions
// ============================================

fn __hi(x: Double) -> Int {
  let bits: Int64 = x.reinterpret_as_int64();
  let shifted: Int64 = bits >> 32;
  shifted.to_int()
}

fn isnan(x: Double) -> Bool {
  let bits: Int64 = x.reinterpret_as_int64();
  let masked: Int64 = bits & 0x7FFFFFFFFFFFFFFFL;
  masked > 0x7FF0000000000000L
}

fn ispinf(x: Double) -> Bool {
  let bits: Int64 = x.reinterpret_as_int64();
  bits == 0x7FF0000000000000L
}

fn uint_gte(a: Int, b: Int) -> Bool {
  let a64: Int64 = a.to_int64() & 0xFFFFFFFFL;
  let b64: Int64 = b.to_int64() & 0xFFFFFFFFL;
  a64 >= b64
}

let nan_bits: Int64 = 0x7FF8000000000000L;
let pos_inf_bits: Int64 = 0x7FF0000000000000L;

fn get_nan() -> Double {
  nan_bits.reinterpret_as_double()
}

fn get_pos_inf() -> Double {
  pos_inf_bits.reinterpret_as_double()
}

// ============================================
// acosh(x): Inverse hyperbolic cosine
// ============================================

fn acosh(x: Double) -> Double {
  let one = 1.0;
  let ln2 = 6.93147180559945286227e-01;
  let hx = __hi(x);
  
  // Domain check: x must be >= 1
  if x < 1.0 || isnan(x) {
    return get_nan();
  } else if x == 1.0 {
    return 0.0;
  } else if ispinf(x) {
    return get_pos_inf();
  } else if uint_gte(hx, 0x41b00000) {
    // x > 2^28
    return log(x) + ln2;
  } else if hx > 0x40000000 {
    // 2^28 > x > 2
    let t = x * x;
    return log(2.0 * x - one / (x + sqrt(t - one)));
  } else {
    // 1 < x < 2
    let t = x - one;
    return log1p(t + sqrt(2.0 * t + t * t));
  }
}

// ============================================
// Test function
// ============================================

fn main {
  println("Testing acosh function:");
  
  // Basic tests
  println(acosh(1.0));     // Should be 0
  println(acosh(2.0));     // Should be ~1.31696
  println(acosh(3.0));     // Should be ~1.76275
  println(acosh(4.0));     // Should be ~2.06344
  println(acosh(5.0));     // Should be ~2.29243
  
  // Larger values
  println(acosh(10.0));    // Should be ~2.99322
  println(acosh(100.0));   // Should be ~5.29829
  
  // Small values (> 1)
  println(acosh(1.1));     // Should be ~0.44357
  println(acosh(1.5));     // Should be ~0.96242
  
  // Additional tests
  println(acosh(6.0));     // Should be ~2.47789
  println(acosh(7.0));     // Should be ~2.63392
  
  // Edge cases - domain errors would return NaN
  // println(acosh(0.5));  // Would be NaN
  // println(acosh(-1.0)); // Would be NaN
}
