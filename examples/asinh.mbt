// asinh(x) function - Inverse hyperbolic sine
// Ported from math.mbt to test MiniMoonBit compiler
//
// Compiler features tested:
// 1. **External C function calls**: sqrt, log, log1p from C math library
// 2. **Complex conditional logic**: multiple ranges with different algorithms
// 3. **Mathematical formula implementation**: asinh(x) = sign(x) * log(|x| + sqrt(x²+1))
// 4. **Type reinterpretation**: Double.reinterpret_as_int64()
// 5. **Bit manipulation**: extracting high 32 bits
// 6. **Special value handling**: NaN, Infinity, tiny values

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

fn isinf(x: Double) -> Bool {
  let bits: Int64 = x.reinterpret_as_int64();
  let masked: Int64 = bits & 0x7FFFFFFFFFFFFFFFL;
  masked == 0x7FF0000000000000L
}

fn fabs(x: Double) -> Double {
  let bits: Int64 = x.reinterpret_as_int64();
  let masked: Int64 = bits & 0x7FFFFFFFFFFFFFFFL;
  masked.reinterpret_as_double()
}

// ============================================
// asinh(x): Inverse hyperbolic sine
// ============================================

fn asinh(x: Double) -> Double {
  if isnan(x) || isinf(x) {
    return x;
  }
  
  let one: Double = 1.0;
  let ln2: Double = 6.93147180559945286227e-01;
  let huge: Double = 1.0e300;
  let hx = __hi(x);
  let ix = hx & 0x7fffffff;
  
  // |x| < 2^-28
  if ix < 0x3e300000 {
    if huge + x > one {
      return x;
    }
  }
  
  // Compute w based on |x|
  let w: Double = if ix > 0x41b00000 {
    // |x| > 2^28, use log(|x|) + ln2
    log(fabs(x)) + ln2
  } else if ix > 0x40000000 {
    // |x| > 2, use log(2|x| + 1/(sqrt(x*x+1)+|x|))
    let t = fabs(x);
    log(2.0 * t + one / (sqrt(x * x + one) + t))
  } else {
    // |x| <= 2, use log1p(|x| + x²/(1 + sqrt(1+x²)))
    let t = x * x;
    log1p(fabs(x) + t / (one + sqrt(one + t)))
  };
  
  // Apply sign
  if hx > 0 {
    w
  } else {
    -w
  }
}

// ============================================
// Test function
// ============================================

fn main {
  println("Testing asinh function:");
  
  // Basic tests
  println(asinh(0.0));     // Should be 0
  println(asinh(1.0));     // Should be ~0.88137
  println(asinh(-1.0));    // Should be ~-0.88137
  println(asinh(2.0));     // Should be ~1.44364
  println(asinh(-2.0));    // Should be ~-1.44364
  
  // Larger values
  println(asinh(5.0));     // Should be ~2.31244
  println(asinh(-5.0));    // Should be ~-2.31244
  println(asinh(10.0));    // Should be ~2.99822
  
  // Small values
  println(asinh(0.1));     // Should be ~0.09983
  println(asinh(-0.1));    // Should be ~-0.09983
  
  // Additional tests
  println(asinh(3.0));     // Should be ~1.81845
  println(asinh(-3.0));    // Should be ~-1.81845
  println(asinh(100.0));   // Should be ~5.29834
}
