#![no_main]

use libfuzzer_sys::fuzz_target;
use libflate::deflate::{Decoder};

fuzz_target!(|data: &[u8]| {
    // fuzzed code goes here
    let mut decoder = Decoder::new(&data[..]);
    std::io::copy(&mut decoder, &mut std::io::sink());
});
