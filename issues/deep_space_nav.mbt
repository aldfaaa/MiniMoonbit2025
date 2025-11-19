extern "C" fn sqrt(x: Double) -> Double = "sqrt"
extern "C" fn float_of_int(x: Int) -> Double = "float_of_int"
extern "C" fn int_of_float(x: Double) -> Int = "int_of_float"

enum Mode {
  Coast;
  Correction(Double);
  GravityAssist(Int);
}

struct Waypoint {
  id: Int;
  vector: (Double, Double, Double);
  mode: Mode;
}

fn magnitude(vec: (Double, Double, Double)) -> Double {
  let (x, y, z) = vec;
  sqrt(x * x + y * y + z * z)
}

fn adjust(wp: Waypoint) -> Waypoint {
  let (vx, vy, vz) = wp.vector;
  match wp.mode {
    Mode::Coast => wp;
    Mode::Correction(delta) => Waypoint::{ id: wp.id, vector: (vx + delta, vy - delta, vz), mode: Mode::Coast };
    Mode::GravityAssist(mult) => Waypoint::{ id: wp.id, vector: (vx * float_of_int(mult), vy, vz), mode: Mode::Coast };
  }
}

fn aggregate(items: Array[Waypoint], len: Int, init: Int, step: (Int, Waypoint) -> Int) -> Int {
  let mut idx = 0;
  let mut acc = init;
  while idx < len {
    acc = step(acc, items[idx]);
    idx = idx + 1;
  }
  acc
}

fn waypoint_acc(acc: Int, wp: Waypoint) -> Int {
  acc + int_of_float(magnitude(wp.vector)) + wp.id % 11
}

fn evaluate(route: Array[Waypoint], len: Int) -> Int {
  let mut idx = 0;
  while idx < len {
    route[idx] = adjust(route[idx]);
    idx = idx + 1;
  }
  aggregate(route, len, 0, waypoint_acc)
}

fn main {
  let route = [
  Waypoint::{
    id: 0,
    vector: (-1.025, -3.105, 4.024),
    mode: Mode::Correction(0.027)
  },
  Waypoint::{
    id: 1,
    vector: (1.967, 3.525, 1.86),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 2,
    vector: (4.917, -3.776, -3.594),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 3,
    vector: (-0.898, 1.698, -3.605),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 4,
    vector: (-0.356, 3.613, -4.397),
    mode: Mode::GravityAssist(2)
  },
  Waypoint::{
    id: 5,
    vector: (-0.568, -3.011, -3.233),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 6,
    vector: (-2.647, 4.483, 0.24),
    mode: Mode::Correction(0.027)
  },
  Waypoint::{
    id: 7,
    vector: (3.154, 2.054, 0.118),
    mode: Mode::Correction(-0.432)
  },
  Waypoint::{
    id: 8,
    vector: (-3.531, -4.863, -3.737),
    mode: Mode::GravityAssist(1)
  },
  Waypoint::{
    id: 9,
    vector: (3.851, -3.96, 0.164),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 10,
    vector: (-1.625, -2.835, -0.654),
    mode: Mode::Correction(0.357)
  },
  Waypoint::{
    id: 11,
    vector: (2.059, 0.706, 1.034),
    mode: Mode::Correction(-0.342)
  },
  Waypoint::{
    id: 12,
    vector: (-1.883, -0.705, 2.553),
    mode: Mode::GravityAssist(4)
  },
  Waypoint::{
    id: 13,
    vector: (-0.243, 1.297, 4.601),
    mode: Mode::GravityAssist(4)
  },
  Waypoint::{
    id: 14,
    vector: (3.22, -4.655, -1.778),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 15,
    vector: (-0.502, 2.697, 2.077),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 16,
    vector: (-4.472, -1.897, -4.683),
    mode: Mode::Correction(-0.3)
  },
  Waypoint::{
    id: 17,
    vector: (4.872, 1.625, 2.477),
    mode: Mode::Correction(-0.028)
  },
  Waypoint::{
    id: 18,
    vector: (-3.638, -1.153, 4.716),
    mode: Mode::GravityAssist(2)
  },
  Waypoint::{
    id: 19,
    vector: (2.422, 2.779, -0.171),
    mode: Mode::Correction(0.119)
  },
  Waypoint::{
    id: 20,
    vector: (-4.101, 1.959, 0.287),
    mode: Mode::Correction(-0.06)
  },
  Waypoint::{
    id: 21,
    vector: (-2.317, -4.979, 3.685),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 22,
    vector: (1.897, 4.087, 2.592),
    mode: Mode::Correction(0.244)
  },
  Waypoint::{
    id: 23,
    vector: (0.764, 3.237, -1.147),
    mode: Mode::Correction(0.153)
  },
  Waypoint::{
    id: 24,
    vector: (-1.997, 4.912, 4.923),
    mode: Mode::GravityAssist(4)
  },
  Waypoint::{
    id: 25,
    vector: (-1.398, -0.572, 1.883),
    mode: Mode::Correction(0.31)
  },
  Waypoint::{
    id: 26,
    vector: (-1.667, -1.056, -1.888),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 27,
    vector: (-3.158, -1.984, -1.755),
    mode: Mode::GravityAssist(4)
  },
  Waypoint::{
    id: 28,
    vector: (-2.945, 3.268, -3.723),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 29,
    vector: (-4.051, 2.368, -0.498),
    mode: Mode::Correction(-0.294)
  },
  Waypoint::{
    id: 30,
    vector: (4.913, -0.479, -3.673),
    mode: Mode::Correction(-0.296)
  },
  Waypoint::{
    id: 31,
    vector: (2.853, -3.369, -1.97),
    mode: Mode::Correction(0.179)
  },
  Waypoint::{
    id: 32,
    vector: (0.245, -3.866, -3.291),
    mode: Mode::GravityAssist(3)
  },
  Waypoint::{
    id: 33,
    vector: (0.67, 1.192, -0.908),
    mode: Mode::GravityAssist(2)
  },
  Waypoint::{
    id: 34,
    vector: (3.53, -1.136, -0.812),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 35,
    vector: (0.278, 2.735, 4.933),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 36,
    vector: (1.628, 3.265, 2.84),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 37,
    vector: (-2.937, 2.897, -0.827),
    mode: Mode::Correction(0.232)
  },
  Waypoint::{
    id: 38,
    vector: (-0.588, -0.712, -2.774),
    mode: Mode::Correction(0.258)
  },
  Waypoint::{
    id: 39,
    vector: (3.213, -2.596, -2.054),
    mode: Mode::GravityAssist(3)
  },
  Waypoint::{
    id: 40,
    vector: (-2.178, -1.733, 3.194),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 41,
    vector: (3.16, -0.396, -2.862),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 42,
    vector: (-1.907, -1.274, -2.845),
    mode: Mode::Correction(-0.319)
  },
  Waypoint::{
    id: 43,
    vector: (-4.786, -2.597, -0.661),
    mode: Mode::GravityAssist(1)
  },
  Waypoint::{
    id: 44,
    vector: (-0.555, 0.81, 1.656),
    mode: Mode::GravityAssist(3)
  },
  Waypoint::{
    id: 45,
    vector: (4.943, -4.766, 3.569),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 46,
    vector: (-4.876, -1.593, 4.916),
    mode: Mode::Correction(0.047)
  },
  Waypoint::{
    id: 47,
    vector: (2.866, -2.071, -1.578),
    mode: Mode::Correction(0.081)
  },
  Waypoint::{
    id: 48,
    vector: (4.118, 3.146, 0.341),
    mode: Mode::Correction(0.162)
  },
  Waypoint::{
    id: 49,
    vector: (-2.289, -4.167, 1.373),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 50,
    vector: (0.611, -3.719, 0.197),
    mode: Mode::Correction(0.407)
  },
  Waypoint::{
    id: 51,
    vector: (-1.356, -3.33, -0.073),
    mode: Mode::Correction(0.267)
  },
  Waypoint::{
    id: 52,
    vector: (-2.81, 3.413, 1.485),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 53,
    vector: (-0.083, 3.378, -1.466),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 54,
    vector: (-2.875, -3.353, 1.831),
    mode: Mode::Correction(0.436)
  },
  Waypoint::{
    id: 55,
    vector: (-1.284, -3.915, -4.236),
    mode: Mode::Correction(0.429)
  },
  Waypoint::{
    id: 56,
    vector: (-2.561, 1.543, -0.531),
    mode: Mode::GravityAssist(4)
  },
  Waypoint::{
    id: 57,
    vector: (-2.826, -0.174, 3.879),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 58,
    vector: (1.61, -0.72, 4.172),
    mode: Mode::Correction(-0.102)
  },
  Waypoint::{
    id: 59,
    vector: (-2.566, 1.824, -4.168),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 60,
    vector: (0.258, 3.177, 2.86),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 61,
    vector: (1.749, 1.71, -0.874),
    mode: Mode::Correction(0.325)
  },
  Waypoint::{
    id: 62,
    vector: (1.516, -4.836, -3.087),
    mode: Mode::Correction(0.409)
  },
  Waypoint::{
    id: 63,
    vector: (-1.813, 2.332, 1.127),
    mode: Mode::Correction(-0.271)
  },
  Waypoint::{
    id: 64,
    vector: (-4.835, -0.886, -2.376),
    mode: Mode::Correction(-0.483)
  },
  Waypoint::{
    id: 65,
    vector: (1.97, 3.357, -2.296),
    mode: Mode::Correction(0.228)
  },
  Waypoint::{
    id: 66,
    vector: (-2.426, -1.903, -1.756),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 67,
    vector: (-0.644, -0.591, 1.22),
    mode: Mode::Correction(0.261)
  },
  Waypoint::{
    id: 68,
    vector: (4.134, 4.672, 1.184),
    mode: Mode::Correction(0.415)
  },
  Waypoint::{
    id: 69,
    vector: (0.187, 3.231, -4.664),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 70,
    vector: (1.558, -3.051, -2.541),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 71,
    vector: (3.137, -2.171, -2.427),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 72,
    vector: (3.323, -0.558, 2.7),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 73,
    vector: (2.065, -3.147, 0.029),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 74,
    vector: (-2.606, -3.997, 0.384),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 75,
    vector: (-3.737, -2.801, 2.715),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 76,
    vector: (-1.039, 4.474, 1.621),
    mode: Mode::GravityAssist(4)
  },
  Waypoint::{
    id: 77,
    vector: (0.644, 0.818, 1.042),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 78,
    vector: (2.95, 4.531, -3.236),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 79,
    vector: (0.385, -3.346, -4.913),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 80,
    vector: (-4.192, -4.758, 4.041),
    mode: Mode::Correction(0.293)
  },
  Waypoint::{
    id: 81,
    vector: (-3.982, 4.175, 2.024),
    mode: Mode::Correction(0.443)
  },
  Waypoint::{
    id: 82,
    vector: (-3.872, 4.186, -3.393),
    mode: Mode::Correction(0.401)
  },
  Waypoint::{
    id: 83,
    vector: (3.816, 0.486, 4.298),
    mode: Mode::Correction(-0.409)
  },
  Waypoint::{
    id: 84,
    vector: (4.658, 4.827, -0.887),
    mode: Mode::GravityAssist(2)
  },
  Waypoint::{
    id: 85,
    vector: (1.962, 1.286, 4.216),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 86,
    vector: (1.99, 2.132, -4.332),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 87,
    vector: (-1.385, 3.35, 1.38),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 88,
    vector: (4.156, -4.556, 4.566),
    mode: Mode::Correction(-0.046)
  },
  Waypoint::{
    id: 89,
    vector: (-3.806, -1.782, 0.757),
    mode: Mode::Correction(-0.498)
  },
  Waypoint::{
    id: 90,
    vector: (2.912, -4.9, 0.155),
    mode: Mode::Correction(-0.35)
  },
  Waypoint::{
    id: 91,
    vector: (1.296, -2.779, 3.326),
    mode: Mode::GravityAssist(2)
  },
  Waypoint::{
    id: 92,
    vector: (-1.326, -0.451, -1.987),
    mode: Mode::GravityAssist(1)
  },
  Waypoint::{
    id: 93,
    vector: (2.965, 2.544, -0.581),
    mode: Mode::Correction(0.256)
  },
  Waypoint::{
    id: 94,
    vector: (-2.266, -0.424, -3.975),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 95,
    vector: (0.995, 3.4, -1.582),
    mode: Mode::Correction(0.348)
  },
  Waypoint::{
    id: 96,
    vector: (4.129, 1.727, -4.806),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 97,
    vector: (3.918, -0.372, 3.254),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 98,
    vector: (-0.872, -3.384, 3.786),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 99,
    vector: (0.497, 3.862, 4.647),
    mode: Mode::Correction(-0.089)
  },
  Waypoint::{
    id: 100,
    vector: (2.817, 1.409, -2.819),
    mode: Mode::GravityAssist(4)
  },
  Waypoint::{
    id: 101,
    vector: (0.871, 1.71, 2.239),
    mode: Mode::GravityAssist(4)
  },
  Waypoint::{
    id: 102,
    vector: (-0.539, -1.718, 0.565),
    mode: Mode::GravityAssist(3)
  },
  Waypoint::{
    id: 103,
    vector: (2.169, 3.973, -0.76),
    mode: Mode::GravityAssist(4)
  },
  Waypoint::{
    id: 104,
    vector: (-4.827, -0.837, 1.513),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 105,
    vector: (-0.017, -0.576, 3.125),
    mode: Mode::GravityAssist(2)
  },
  Waypoint::{
    id: 106,
    vector: (3.981, 1.661, 1.459),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 107,
    vector: (3.516, 0.468, 3.372),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 108,
    vector: (3.27, 3.058, 4.282),
    mode: Mode::GravityAssist(2)
  },
  Waypoint::{
    id: 109,
    vector: (-4.925, 0.085, 4.859),
    mode: Mode::Correction(-0.128)
  },
  Waypoint::{
    id: 110,
    vector: (4.471, -2.442, 3.592),
    mode: Mode::GravityAssist(3)
  },
  Waypoint::{
    id: 111,
    vector: (-2.633, 3.637, 3.643),
    mode: Mode::Correction(-0.456)
  },
  Waypoint::{
    id: 112,
    vector: (3.414, -3.411, -2.219),
    mode: Mode::Correction(-0.149)
  },
  Waypoint::{
    id: 113,
    vector: (0.818, 1.887, -1.324),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 114,
    vector: (-3.73, -2.204, -4.61),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 115,
    vector: (3.975, -3.778, -3.945),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 116,
    vector: (1.614, 2.467, -4.49),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 117,
    vector: (1.028, 2.146, 1.692),
    mode: Mode::Correction(0.342)
  },
  Waypoint::{
    id: 118,
    vector: (0.904, 0.454, -2.175),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 119,
    vector: (-0.14, -0.549, -1.17),
    mode: Mode::Correction(-0.1)
  },
  Waypoint::{
    id: 120,
    vector: (2.081, -1.563, -4.92),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 121,
    vector: (3.548, 1.104, 3.771),
    mode: Mode::Correction(0.106)
  },
  Waypoint::{
    id: 122,
    vector: (2.363, 0.8, -3.874),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 123,
    vector: (-0.613, 1.435, 0.066),
    mode: Mode::GravityAssist(3)
  },
  Waypoint::{
    id: 124,
    vector: (0.219, 4.492, -0.665),
    mode: Mode::Correction(-0.099)
  },
  Waypoint::{
    id: 125,
    vector: (4.563, 2.819, -1.578),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 126,
    vector: (1.653, 0.614, 2.513),
    mode: Mode::GravityAssist(3)
  },
  Waypoint::{
    id: 127,
    vector: (4.442, 3.007, -1.712),
    mode: Mode::GravityAssist(4)
  },
  Waypoint::{
    id: 128,
    vector: (-0.946, -2.648, 1.219),
    mode: Mode::Correction(0.242)
  },
  Waypoint::{
    id: 129,
    vector: (-4.887, 3.833, 0.789),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 130,
    vector: (1.933, -1.921, -0.72),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 131,
    vector: (-0.218, 3.519, 3.346),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 132,
    vector: (-2.41, 4.266, -4.599),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 133,
    vector: (-4.343, 0.189, 3.997),
    mode: Mode::GravityAssist(1)
  },
  Waypoint::{
    id: 134,
    vector: (3.639, -2.839, 2.521),
    mode: Mode::Correction(0.195)
  },
  Waypoint::{
    id: 135,
    vector: (-1.077, -4.785, 2.556),
    mode: Mode::Correction(-0.487)
  },
  Waypoint::{
    id: 136,
    vector: (-2.837, 1.893, -1.339),
    mode: Mode::GravityAssist(4)
  },
  Waypoint::{
    id: 137,
    vector: (2.345, 1.133, 1.718),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 138,
    vector: (3.732, -0.704, -3.809),
    mode: Mode::GravityAssist(4)
  },
  Waypoint::{
    id: 139,
    vector: (-1.512, -1.318, -3.42),
    mode: Mode::Correction(-0.466)
  },
  Waypoint::{
    id: 140,
    vector: (3.288, -1.572, 0.497),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 141,
    vector: (-1.642, 1.229, -0.156),
    mode: Mode::GravityAssist(3)
  },
  Waypoint::{
    id: 142,
    vector: (-1.581, -1.67, 0.762),
    mode: Mode::GravityAssist(4)
  },
  Waypoint::{
    id: 143,
    vector: (3.764, -0.467, 3.369),
    mode: Mode::GravityAssist(1)
  },
  Waypoint::{
    id: 144,
    vector: (-2.028, -4.182, -2.108),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 145,
    vector: (-4.01, -4.327, 1.085),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 146,
    vector: (1.851, -0.279, 4.443),
    mode: Mode::GravityAssist(3)
  },
  Waypoint::{
    id: 147,
    vector: (0.974, -2.523, 4.362),
    mode: Mode::GravityAssist(4)
  },
  Waypoint::{
    id: 148,
    vector: (4.804, 2.646, -4.712),
    mode: Mode::GravityAssist(1)
  },
  Waypoint::{
    id: 149,
    vector: (0.841, -4.044, 1.012),
    mode: Mode::Correction(-0.309)
  },
  Waypoint::{
    id: 150,
    vector: (-0.861, 4.156, 4.899),
    mode: Mode::Correction(0.065)
  },
  Waypoint::{
    id: 151,
    vector: (-0.508, 1.8, 1.186),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 152,
    vector: (-0.691, -4.024, -1.71),
    mode: Mode::Correction(-0.175)
  },
  Waypoint::{
    id: 153,
    vector: (-3.374, -3.293, -3.452),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 154,
    vector: (0.119, 1.701, -3.775),
    mode: Mode::Correction(0.452)
  },
  Waypoint::{
    id: 155,
    vector: (-3.816, 2.841, 0.369),
    mode: Mode::Correction(-0.411)
  },
  Waypoint::{
    id: 156,
    vector: (1.312, 1.526, -2.578),
    mode: Mode::Correction(0.07)
  },
  Waypoint::{
    id: 157,
    vector: (1.327, 1.837, 0.352),
    mode: Mode::Coast
  },
  Waypoint::{
    id: 158,
    vector: (-0.858, 4.594, -0.344),
    mode: Mode::GravityAssist(3)
  },
  Waypoint::{
    id: 159,
    vector: (0.332, 1.98, 4.962),
    mode: Mode::GravityAssist(3)
  }
];
  println(evaluate(route, 160));
}
