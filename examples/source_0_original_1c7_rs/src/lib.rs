use std::ffi::OsString;
use std::fs;
use std::io::Error;

// https://github.com/sile/libflate/issues/64
// b"\x04\x04\x04\x05:\x1az*\xfc\x06\x01\x90\x01\x06\x01"
pub fn fuzz_target(data : &[u8]) -> Result<(), Error> {
    use libflate::deflate::{Decoder};
    
    let mut decoder = Decoder::new(&data[..]);
    std::io::copy(&mut decoder, &mut std::io::sink());
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
