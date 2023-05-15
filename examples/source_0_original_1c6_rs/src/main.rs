use bel;
use std::env;
use std::io::Error;

fn main() -> Result<(), Error> {
    let args: Vec<String> = env::args().collect();
    match args.get(1) {
        Some(file) => bel::main0(vec!["".into(), file.into()]),
        None => Ok(())
    }
}
