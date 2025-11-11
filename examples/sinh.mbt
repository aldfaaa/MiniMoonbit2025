// sinh(x) function - Hyperbolic sine
// Ported from math.mbt to test MiniMoonBit compiler
//
// Compiler features tested:
// 1. **Function composition**: sinh calls exp, expm1, and fabs
// 2. **Complex conditional logic**: multiple ranges of x with different algorithms
// 3. **Type reinterpretation**: Double.reinterpret_as_int64() for special value handling
// 4. **Unsigned 64-bit comparison**: handling Int64 as unsigned for comparison
// 5. **Bit manipulation**: extracting high 32 bits
// 6. **Special value handling**: NaN, Infinity

// ============================================
// Helper functions for double precision bit manipulation
// ============================================

// Get high 32 bits of a double as Int
fn __hi(x: Double) -> Int {
  let bits: Int64 = x.reinterpret_as_int64();
  let shifted: Int64 = bits >> 32;
  shifted.to_int()
}

// Get low 32 bits of a double as Int
fn __low(x: Double) -> Int {
  let bits: Int64 = x.reinterpret_as_int64();
  bits.to_int()
}

// Combine high and low 32-bit integers to form a double
fn __combineW(hi: Int, low: Int) -> Double {
  let hi64: Int64 = hi.to_int64();
  let low64: Int64 = low.to_int64();
  // Mask low64 to ensure it's treated as unsigned 32 bits
  let low_masked: Int64 = low64 & 0xFFFFFFFFL;
  let combined: Int64 = (hi64 << 32) | low_masked;
  combined.reinterpret_as_double()
}

// Check if double is NaN
fn isnan(x: Double) -> Bool {
  let bits: Int64 = x.reinterpret_as_int64();
  let masked: Int64 = bits & 0x7FFFFFFFFFFFFFFFL;
  masked > 0x7FF0000000000000L
}

// Check if double is infinite
fn isinf(x: Double) -> Bool {
  let bits: Int64 = x.reinterpret_as_int64();
  let masked: Int64 = bits & 0x7FFFFFFFFFFFFFFFL;
  masked == 0x7FF0000000000000L
}

// Absolute value using bit manipulation
fn fabs(x: Double) -> Double {
  let bits: Int64 = x.reinterpret_as_int64();
  let masked: Int64 = bits & 0x7FFFFFFFFFFFFFFFL;
  masked.reinterpret_as_double()
}

// Simulate unsigned comparison for Int
fn uint_gte(a: Int, b: Int) -> Bool {
  let a64: Int64 = a.to_int64() & 0xFFFFFFFFL;
  let b64: Int64 = b.to_int64() & 0xFFFFFFFFL;
  a64 >= b64
}

// Simulate unsigned less-than comparison for Int64
fn uint64_lt(a: Int64, b: Int64) -> Bool {
  // For unsigned comparison, we need to handle the sign bit differently
  // If both have same sign bit, normal comparison works
  // If signs differ, negative (in signed) is actually larger (in unsigned)
  let a_sign: Bool = a < 0L;
  let b_sign: Bool = b < 0L;
  if a_sign == b_sign {
    a < b
  } else {
    // a is negative (larger in unsigned), b is positive (smaller in unsigned)
    !a_sign
  }
}

// Constants
let nan_bits: Int64 = 0x7FF8000000000000L;
let pos_inf_bits: Int64 = 0x7FF0000000000000L;

fn get_nan() -> Double {
  nan_bits.reinterpret_as_double()
}

fn get_pos_inf() -> Double {
  pos_inf_bits.reinterpret_as_double()
}

// ============================================
// expm1(x): Compute exp(x) - 1 accurately (simplified version for sinh)
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
// exp(x): Exponential function (simplified version for sinh)
// ============================================

fn exp(input: Double) -> Double {
  let mut x = input;
  let one = 1.0;
  let halF = [0.5, -0.5];
  let o_threshold = 7.09782712893383973096e+02;
  let u_threshold = -7.45133219101941108420e+02;
  let ln2HI = [6.93147180369123816490e-01, -6.93147180369123816490e-01];
  let ln2LO = [1.90821492927058770002e-10, -1.90821492927058770002e-10];
  let invln2 = 1.44269504088896338700e+00;
  let p1 = 1.66666666666666019037e-01;
  let p2 = -2.77777777770155933842e-03;
  let p3 = 6.61375632143793436117e-05;
  let p4 = -1.65339022054652515390e-06;
  let p5 = 4.13813679705723846039e-08;
  let e = 2.718281828459045;
  let mut hi = 0.0;
  let mut lo = 0.0;
  let huge = 1.0e+300;
  let twom1000 = 9.33263618503218878990e-302;
  let two1023 = 8.988465674311579539e307;
  let mut k: Int = 0;
  
  let mut hx: Int = __hi(input);
  let sign_mask: Int = (1L << 31).to_int();
  let xsb: Int = (hx & sign_mask) >> 31;
  hx = hx & 0x7FFFFFFF;
  
  if uint_gte(hx, 0x40862E42) {
    if uint_gte(hx, 0x7FF00000) {
      let lx: Int = __low(input);
      if ((hx & 0xFFFFF) | lx) != 0 {
        return input + input;
      } else if xsb == 0 {
        return input;
      } else {
        return 0.0;
      }
    }
    if input > o_threshold {
      return huge * huge;
    }
    if input < u_threshold {
      return twom1000 * twom1000;
    }
  }
  
  if uint_gte(hx, 0x3FD62E42 + 1) {
    if hx < 0x3FF0A2B2 {
      if input == 1.0 {
        return e;
      }
      hi = input - ln2HI[xsb];
      lo = ln2LO[xsb];
      k = 1 - xsb - xsb;
    } else {
      k = (invln2 * input + halF[xsb]).to_int();
      let t = k.to_double();
      hi = input - t * ln2HI[0];
      lo = t * ln2LO[0];
    }
    x = hi - lo;
  } else if hx < 0x3E300000 {
    if huge + x > one {
      return one + x;
    }
  } else {
    k = 0;
  }
  
  let t = x * x;
  
  let twopk = if k >= -1021 {
    let exp_bits: Int = 0x3FF00000 + (k << 20);
    __combineW(exp_bits, 0)
  } else {
    let exp_bits: Int = 0x3FF00000 + ((k + 1000) << 20);
    __combineW(exp_bits, 0)
  };
  
  let c = x - t * (p1 + t * (p2 + t * (p3 + t * (p4 + t * p5))));
  
  if k == 0 {
    return one - (x * c / (c - 2.0) - x);
  }
  
  let y = one - (lo - x * c / (2.0 - c) - hi);
  
  if k >= -1021 {
    if k == 1024 {
      return y * 2.0 * two1023;
    } else {
      return y * twopk;
    }
  } else {
    return y * twopk * twom1000;
  }
}

// ============================================
// sinh(x): Hyperbolic sine function
// ============================================

fn sinh(x: Double) -> Double {
  if isnan(x) || isinf(x) {
    return x;
  }
  
  let ix = __hi(x) & 0x7fffffff;
  let abs_x = fabs(x);
  let shuge = 1.0e307;
  let h = if x < 0.0 { -0.5 } else { 0.5 };
  
  // |x| < 22
  if ix < 0x40360000 {
    // |x| < 2^-28
    if ix < 0x3e300000 {
      if shuge + x > 1.0 {
        return x;
      }
    }
    let t = expm1(abs_x);
    // |x| < 1
    if ix < 0x3ff00000 {
      return h * (2.0 * t - t * t / (t + 1.0));
    }
    return h * (t + t / (t + 1.0));
  }
  
  // 22 <= |x| < log(maxdouble)
  if ix < 0x40862E42 {
    return h * exp(abs_x);
  }
  
  // |x| < overflowthreshold
  // Check if abs_x < 710.4758600739439 (as uint64: 0x408633ce8fb9f87d)
  let abs_x_bits: Int64 = abs_x.reinterpret_as_int64();
  let threshold: Int64 = 0x408633ce8fb9f87dL;
  if uint64_lt(abs_x_bits, threshold) {
    let w = exp(0.5 * abs_x);
    let t = h * w;
    return t * w;
  }
  
  // Overflow
  x * shuge
}

// ============================================
// Test function
// ============================================

fn main {
  println("Testing sinh function:");
  
  // Basic tests
  println(sinh(0.0));     // Should be 0
  println(sinh(1.0));     // Should be ~1.17520
  println(sinh(-1.0));    // Should be ~-1.17520
  println(sinh(0.5));     // Should be ~0.52110
  println(sinh(-0.5));    // Should be ~-0.52110
  
  // Larger values
  println(sinh(2.0));     // Should be ~3.62686
  println(sinh(-2.0));    // Should be ~-3.62686
  println(sinh(3.0));     // Should be ~10.0179
  println(sinh(5.0));     // Should be ~74.2032
  
  // Small values
  println(sinh(0.1));     // Should be ~0.10017
  println(sinh(-0.1));    // Should be ~-0.10017
  
  // Edge cases
  println(sinh(10.0));    // Should be ~11013.2
  println(sinh(-10.0));   // Should be ~-11013.2
  
  // Additional tests
  println(sinh(0.7));     // Should be ~0.75858
  println(sinh(-0.7));    // Should be ~-0.75858
}

