use std::ffi::OsString;
use std::fs;
use std::io::Error;

use mp4ameta;

fn main00(mut args : impl Iterator<Item = OsString>) -> Result<(), Error> {
    match args.next() {
        Some(_) => {
    match args.next() {
        Some(file) => {
            let data = fs::read(file).expect("Error reading the file");
            let mut data = std::io::Cursor::new(data);
            mp4ameta::Tag::read_from(&mut data);

            // https://github.com/Saecki/mp4ameta/issues/25
            // [0, 0, 0, 1, 102, 116, 121, 112, 0, 132, 255, 255, 255, 255, 0, 132]
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
