// tanh(x) function - Hyperbolic tangent
// Ported from math.mbt to test MiniMoonBit compiler
//
// Compiler features tested:
// 1. **Function composition**: tanh calls expm1 and fabs
// 2. **Complex conditional logic**: nested if-else with multiple conditions
// 3. **Special value detection**: ispinf and isninf implementations
// 4. **Type reinterpretation**: Double.reinterpret_as_int64()
// 5. **Bit manipulation**: extracting high 32 bits
// 6. **Special value handling**: NaN, +Infinity, -Infinity

// ============================================
// Helper functions
// ============================================

fn __hi(x: Double) -> Int {
  let bits: Int64 = x.reinterpret_as_int64();
  let shifted: Int64 = bits >> 32;
  shifted.to_int()
}

fn __low(x: Double) -> Int {
  let bits: Int64 = x.reinterpret_as_int64();
  bits.to_int()
}

fn __combineW(hi: Int, low: Int) -> Double {
  let hi64: Int64 = hi.to_int64();
  let low64: Int64 = low.to_int64();
  let low_masked: Int64 = low64 & 0xFFFFFFFFL;
  let combined: Int64 = (hi64 << 32) | low_masked;
  combined.reinterpret_as_double()
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

// Check if double is positive infinity
fn ispinf(x: Double) -> Bool {
  let bits: Int64 = x.reinterpret_as_int64();
  bits == 0x7FF0000000000000L
}

// Check if double is negative infinity
fn isninf(x: Double) -> Bool {
  let bits: Int64 = x.reinterpret_as_int64();
  // Sign bit set (negative) and exponent all 1s and mantissa all 0s
  // 0xfff0000000000000 = -inf
  let neg_inf: Int64 = 0x7FF0000000000000L | (1L << 63);
  bits == neg_inf
}

fn fabs(x: Double) -> Double {
  let bits: Int64 = x.reinterpret_as_int64();
  let masked: Int64 = bits & 0x7FFFFFFFFFFFFFFFL;
  masked.reinterpret_as_double()
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
// expm1(x): Compute exp(x) - 1
// ============================================

fn expm1(x: Double) -> Double {
  if isnan(x) {
    return get_nan();
  }
  
  let o_threshold = 7.09782712893383973096e+02;
  if x > o_threshold {
    return get_pos_inf();
  }
  
  if isinf(x) {
    return -1.0;
  }
  
  let one = 1.0;
  let huge = 1.0e+300;
  let tiny = 1.0e-300;
  let ln2_hi = 6.93147180369123816490e-01;
  let ln2_lo = 1.90821492927058770002e-10;
  let invln2 = 1.44269504088896338700e+00;
  let q1 = -3.33333333333331316428e-02;
  let q2 = 1.58730158725481460165e-03;
  let q3 = -7.93650757867487942473e-05;
  let q4 = 4.00821782732936239552e-06;
  let q5 = -2.01099218183624371326e-07;
  
  let mut x = x;
  let mut hx = __hi(x);
  let sign_mask: Int = (1L << 31).to_int();
  let xsb: Int = hx & sign_mask;
  let mut y: Double = if xsb == 0 { x } else { -x };
  hx = hx & 0x7fffffff;
  
  if uint_gte(hx, 0x4043687A) {
    if xsb != 0 {
      if x + tiny < 0.0 {
        return tiny - one;
      }
    }
  }
  
  let mut hi = 0.0;
  let mut lo = 0.0;
  let mut k = 0;
  let mut c = 0.0;
  let mut t = 0.0;
  
  if uint_gte(hx, 0x3fd62e42 + 1) {
    if hx < 0x3FF0A2B2 {
      hi = if xsb == 0 { x - ln2_hi } else { x + ln2_hi };
      lo = if xsb == 0 { ln2_lo } else { -ln2_lo };
      k = if xsb == 0 { 1 } else { -1 };
    } else {
      k = (invln2 * x + (if xsb == 0 { 0.5 } else { -0.5 })).to_int();
      t = k.to_double();
      hi = x - t * ln2_hi;
      lo = t * ln2_lo;
    }
    x = hi - lo;
    c = hi - x - lo;
  } else if hx < 0x3c900000 {
    t = huge + x;
    return x - (t - (huge + x));
  } else {
    k = 0;
  }
  
  let hfx: Double = 0.5 * x;
  let hxs: Double = x * hfx;
  let r1: Double = one + hxs * (q1 + hxs * (q2 + hxs * (q3 + hxs * (q4 + hxs * q5))));
  let t: Double = 3.0 - r1 * hfx;
  let e: Double = hxs * ((r1 - t) / (6.0 - x * t));
  
  if k == 0 {
    return x - (x * e - hxs);
  } else {
    let e: Double = x * (e - c) - c;
    let e: Double = e - hxs;
    if k == -1 {
      return 0.5 * (x - e) - 0.5;
    }
    if k == 1 {
      return if x < -0.25 {
        -2.0 * (e - (x + 0.5))
      } else {
        one + 2.0 * (x - e)
      };
    }
    if k <= -2 || k > 56 {
      y = one - (e - x);
      let new_hi = __hi(y) + (k << 20);
      y = __combineW(new_hi, __low(y));
      return y - one;
    }
    let mut t: Double = one;
    if k < 20 {
      let shifted = 0x200000 >> k;
      let new_hi = 0x3ff00000 - shifted;
      t = __combineW(new_hi, 0);
      y = t - (e - x);
      let new_hi = __hi(y) + (k << 20);
      y = __combineW(new_hi, __low(y));
    } else {
      let new_hi = (0x3ff - k) << 20;
      t = __combineW(new_hi, 0);
      y = x - (e + t) + one;
      let new_hi = __hi(y) + (k << 20);
      y = __combineW(new_hi, __low(y));
    }
  }
  y
}

// ============================================
// tanh(x): Hyperbolic tangent function
// ============================================

fn tanh(x: Double) -> Double {
  if isnan(x) {
    return x;
  }
  if ispinf(x) {
    return 1.0;
  }
  if isninf(x) {
    return -1.0;
  }
  
  let ix = __hi(x) & 0x7fffffff;
  let tiny = 1.0e-300;
  
  // Compute z based on |x|
  let z = if ix < 0x40360000 {
    // |x| < 22
    if ix < 0x3c800000 {
      // |x| < 2^-27, tanh(x) ≈ x
      x * (1.0 + x)
    } else if uint_gte(ix, 0x3ff00000) {
      // |x| >= 1
      let t = expm1(2.0 * fabs(x));
      1.0 - 2.0 / (t + 2.0)
    } else {
      // 2^-27 <= |x| < 1
      let t = expm1(-2.0 * fabs(x));
      -t / (t + 2.0)
    }
  } else {
    // |x| >= 22, tanh(x) ≈ ±1
    1.0 - tiny
  };
  
  // Apply sign
  if x >= 0.0 {
    z
  } else {
    -z
  }
}

// ============================================
// Test function
// ============================================

fn main {
  println("Testing tanh function:");
  
  // Basic tests
  println(tanh(0.0));     // Should be 0
  println(tanh(1.0));     // Should be ~0.76159
  println(tanh(-1.0));    // Should be ~-0.76159
  println(tanh(0.5));     // Should be ~0.46212
  println(tanh(-0.5));    // Should be ~-0.46212
  
  // Larger values
  println(tanh(2.0));     // Should be ~0.96403
  println(tanh(-2.0));    // Should be ~-0.96403
  println(tanh(3.0));     // Should be ~0.99505
  println(tanh(5.0));     // Should be ~0.99991
  
  // Small values
  println(tanh(0.1));     // Should be ~0.09967
  println(tanh(-0.1));    // Should be ~-0.09967
  
  // Edge cases (approach ±1)
  println(tanh(10.0));    // Should be ~1.0
  println(tanh(-10.0));   // Should be ~-1.0
  println(tanh(20.0));    // Should be ~1.0
  println(tanh(-20.0));   // Should be ~-1.0
  
  // Additional tests
  println(tanh(0.7));     // Should be ~0.60437
  println(tanh(-0.7));    // Should be ~-0.60437
}

