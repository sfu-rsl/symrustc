use std::ffi::OsString;
use std::fs;
use std::io::Error;

pub fn fuzz_target(data : &[u8]) -> Result<(), Error> {
    let data = String::from_utf8_lossy(&data);
    csscolorparser::parse(&data);
    Ok(())
}

pub fn main0(args : Vec<OsString>) -> Result<(), Error> {
    match args.get(1) {
        Some(file) => {
            let data = fs::read(file).expect("Error reading the file");
            fuzz_target(&data)
        }
        None => Ok(())
    }
}
