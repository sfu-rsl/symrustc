use std::io::Read;

fn main() {
    let mut input = [0u8; 12];
    std::io::stdin().read_exact(&mut input).unwrap();
    bel::main0(&input);
}