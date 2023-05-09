#![no_main]

use std::io::Write;

use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    let c_name = std::ffi::CString::new("test-fifo").unwrap();
    let name = c_name.to_str().unwrap().to_owned();
    // std::fs::remove_file(&name_str);
    unsafe {
        if libc::mkfifo(c_name.as_ptr(), 0o644) != 0 {
            // If it already exists, that's fine.
        }
    }

    let handle = {
        let name = name.clone();
        let data = data.to_vec();
        std::thread::spawn(move || {
            while std::fs::OpenOptions::new()
                .write(true)
                .open(&name)
                .unwrap()
                .write_all(&data)
                .is_err()
            {}
        })
    };

    uu_base64::uumain(vec!["".into(), name.into()].iter().cloned());
    handle.join().unwrap();
});
