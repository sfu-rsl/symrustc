use std::io;
use std::env;
use std::fs;
use bel;

fn main() -> Result<(), io::Error> {
    let args: Vec<String> = env::args().collect();
    match args.get(1) {
        Some(file) => {
            match bel::main0(fs::read(file).expect("Error reading the file")) {
                Some(_) => Ok(()),
                None => panic!("Artificial bug")
            }
        }
        None => Ok(())
    }
}
