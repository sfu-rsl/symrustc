use std::ffi::OsString;
use std::fs;
use std::io::Error;

// https://github.com/Saecki/mp4ameta/issues/25
// [0, 0, 0, 1, 102, 116, 121, 112, 0, 132, 255, 255, 255, 255, 0, 132]
pub fn fuzz_target(data : &[u8]) -> Result<(), Error> {
    use mp4ameta;
    
    let mut data = std::io::Cursor::new(data);
    mp4ameta::Tag::read_from(&mut data);
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
