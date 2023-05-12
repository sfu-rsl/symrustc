use std::ffi::OsString;
use std::fs;
use std::io::Error;

fn main00(mut args : impl Iterator<Item = OsString>) -> Result<(), Error> {
    match args.next() {
        Some(_) => {
    match args.next() {
        Some(file) => {
            let buf = fs::read(file).expect("Error reading the file");
            let s = String::from_utf8_lossy(&buf);
            csscolorparser::parse(&s);
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
