extern crate libc;

extern {
    fn c_main() -> libc::c_int;
}

fn main() {
    println!("extern exit code: {}", unsafe { c_main() });
}
