use std::ffi::OsString;
use std::fs;
use std::io::Error;

use lz4_flex::block::decompress::decompress_size_prepended;
use lz4::block::compress as lz4_linked_block_compress;

fn main00(mut args : impl Iterator<Item = OsString>) -> Result<(), Error> {
    match args.next() {
        Some(_) => {
    match args.next() {
        Some(file) => {
            let data = fs::read(file).expect("Error reading the file");
            let compressed = lz4_linked_block_compress(&data, None, true).unwrap();
            let decompressed = decompress_size_prepended(&compressed).unwrap();
            assert_eq!(data, decompressed);
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
