// atanh(x) function - Inverse hyperbolic tangent
// Ported from math.mbt to test MiniMoonBit compiler
//
// Compiler features tested:
// 1. **External C function calls**: log1p from C math library
// 2. **Domain checking**: |x| must be <= 1
// 3. **Special boundary values**: atanh(±1) = ±infinity
// 4. **Mathematical formula**: atanh(x) = 0.5 * log((1+x)/(1-x))
// 5. **Conditional algorithm selection**: different formulas for |x| <= 0.5 vs |x| > 0.5

// ============================================
// Extern C functions
// ============================================

extern "C" fn log1p(x: Double) -> Double = "log1p";

// ============================================
// Helper functions
// ============================================

fn __hi(x: Double) -> Int {
  let bits: Int64 = x.reinterpret_as_int64();
  let shifted: Int64 = bits >> 32;
  shifted.to_int()
}

fn fabs(x: Double) -> Double {
  let bits: Int64 = x.reinterpret_as_int64();
  let masked: Int64 = bits & 0x7FFFFFFFFFFFFFFFL;
  masked.reinterpret_as_double()
}

let nan_bits: Int64 = 0x7FF8000000000000L;
let pos_inf_bits: Int64 = 0x7FF0000000000000L;

fn get_nan() -> Double {
  nan_bits.reinterpret_as_double()
}

fn get_pos_inf() -> Double {
  pos_inf_bits.reinterpret_as_double()
}

fn get_neg_inf() -> Double {
  let sign_bit: Int64 = 1L << 63;
  let neg_inf_bits: Int64 = pos_inf_bits | sign_bit;
  neg_inf_bits.reinterpret_as_double()
}

// ============================================
// atanh(x): Inverse hyperbolic tangent
// ============================================

fn atanh(x: Double) -> Double {
  let hx: Int = __hi(x);
  let ix = hx & 0x7fffffff;
  
  // Domain check: |x| must be <= 1
  if fabs(x) > 1.0 {
    return get_nan();
  }
  
  // Special cases: atanh(±1) = ±infinity
  if x == 1.0 {
    return get_pos_inf();
  }
  if x == -1.0 {
    return get_neg_inf();
  }
  
  // For very small |x|, return x
  if ix < 0x3e300000 && 1.0e300 + x > 0.0 {
    return x;
  }
  
  // Compute using log1p
  let x_abs = fabs(x);
  let t = if x_abs <= 0.5 {
    // For |x| <= 0.5, use log1p(2x + 2x²/(1-x))
    let t = x_abs + x_abs;
    0.5 * log1p(t + t * x_abs / (1.0 - x_abs))
  } else {
    // For 0.5 < |x| < 1, use log1p(2x/(1-x))
    0.5 * log1p((x_abs + x_abs) / (1.0 - x_abs))
  };
  
  // Apply sign
  if hx >= 0 {
    t
  } else {
    -t
  }
}

// ============================================
// Test function
// ============================================

fn main {
  println("Testing atanh function:");
  
  // Basic tests
  println(atanh(0.0));     // Should be 0
  println(atanh(0.5));     // Should be ~0.54931
  println(atanh(-0.5));    // Should be ~-0.54931
  println(atanh(0.3));     // Should be ~0.30952
  println(atanh(-0.3));    // Should be ~-0.30952
  
  // Near boundaries
  println(atanh(0.9));     // Should be ~1.47222
  println(atanh(-0.9));    // Should be ~-1.47222
  println(atanh(0.99));    // Should be ~2.64665
  println(atanh(-0.99));   // Should be ~-2.64665
  
  // Small values
  println(atanh(0.1));     // Should be ~0.10034
  println(atanh(-0.1));    // Should be ~-0.10034
  
  // Additional tests
  println(atanh(0.7));     // Should be ~0.86730
  println(atanh(-0.7));    // Should be ~-0.86730
  println(atanh(0.8));     // Should be ~1.09861
  println(atanh(-0.8));    // Should be ~-1.09861
  
  // Boundary values (commented out as they return infinity)
  // println(atanh(1.0));   // Would be +inf
  // println(atanh(-1.0));  // Would be -inf
  
  // Domain errors (commented out as they return NaN)
  // println(atanh(1.5));   // Would be NaN
  // println(atanh(-1.5));  // Would be NaN
}
