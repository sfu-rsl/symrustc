#![no_main]

use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    // fuzzed code goes here
    let mut data = std::io::Cursor::new(data);
    mp4ameta::Tag::read_from(&mut data);
});
