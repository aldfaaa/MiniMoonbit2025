
fn print_bool_value(v: Bool) -> Unit {
  match v {
    true => println("It's true!")
    false => println("It's false!")
  }
}

fn main {
  print_bool_value(true)
  print_bool_value(false)
}
