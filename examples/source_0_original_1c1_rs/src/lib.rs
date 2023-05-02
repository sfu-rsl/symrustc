use std::ffi::OsString;
use std::io::Error;
use uu_sort;

pub fn main0(args : Vec<OsString>) -> Result<(), Error> {
    match uu_sort::uumain(args.iter().cloned()) {
        0 => Ok(()),
        code => {
            eprintln!("Error exit code: {:?}", code);
            Ok(())
        }
    }
}
