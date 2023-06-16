#![no_main]

use bel;
use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    bel::fuzz_target(data);
});
