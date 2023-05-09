pub fn main0(input: &[u8]) {
    use std::convert::TryInto;
    use std::mem::size_of;
    use std::time::Duration;
    if input.len() != size_of::<u64>() + size_of::<u32>() {
        return;
    }
    let (secs, nanos) = input.split_at(size_of::<u64>());

    let mut buffer = [0u8; 14];
    let secs = u64::from_ne_bytes(unsafe { secs.try_into().unwrap_unchecked() });
    let nanos = u32::from_ne_bytes(unsafe { nanos.try_into().unwrap_unchecked() });

    bincode::encode_into_slice(
        &(secs, nanos),
        &mut buffer,
        bincode::config::Configuration::standard(),
    )
    .unwrap();

    let result: Result<(Duration, usize), _> =
        bincode::decode_from_slice(&buffer, bincode::config::Configuration::standard());

    if let Ok((dur, _)) = result {
        if let Some(input_dur) = Duration::checked_add(
            Duration::from_secs(secs),
            Duration::from_nanos(nanos as u64),
        ) {
            assert_eq!(dur, input_dur);
        }
    }
}
