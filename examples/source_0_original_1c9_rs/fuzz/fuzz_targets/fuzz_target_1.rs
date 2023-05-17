#![no_main]

use std::time::Duration;

use bincode::config::Configuration;
use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: Duration| {
    let mut input = [0u8; 14];
    bincode::encode_into_slice(&data, &mut input, Configuration::standard())
        .unwrap();

    let result: Result<(std::time::Duration, usize), _> =
        bincode::decode_from_slice(&mut input, Configuration::standard());

    assert_eq!(data, result.unwrap().0);
});
