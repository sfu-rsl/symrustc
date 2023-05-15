use std::ffi::OsString;
use std::fs;
use std::io::Error;

use chrono;

fn main00(mut args : impl Iterator<Item = OsString>) -> Result<(), Error> {
    match args.next() {
        Some(_) => {
    match args.next() {
        Some(file) => {
            let buf = fs::read(file).expect("Error reading the file");
            let s = String::from_utf8_lossy(&buf);
            chrono::DateTime::parse_from_rfc2822(&s);
            // https://github.com/chronotope/chrono/commit/ad03bcbdcb27c7010c21fca0f8a3440b69e994fc
            // "31 DEC 262143 23:59 -2359"
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
