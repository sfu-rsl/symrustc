use std::ffi::OsString;
use std::fs;
use std::io::Error;

use libflate::deflate::{Decoder};

fn main00(mut args : impl Iterator<Item = OsString>) -> Result<(), Error> {
    match args.next() {
        Some(_) => {
    match args.next() {
        Some(file) => {
            let input = fs::read(file).expect("Error reading the file");
            let mut decoder = Decoder::new(&input[..]);
                                                                        
            std::io::copy(&mut decoder, &mut std::io::sink());
            // https://github.com/sile/libflate/issues/64
            // b"\x04\x04\x04\x05:\x1az*\xfc\x06\x01\x90\x01\x06\x01"
            Ok(())
        }
        None => Ok(())
    }
    }
        None => Ok(())
    }
}

pub fn main0(args : Vec<OsString>) -> Result<(), Error> {
    main00(args.iter().cloned())
}
