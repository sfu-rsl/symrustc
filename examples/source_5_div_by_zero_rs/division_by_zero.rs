fn foo(s: &String, t1: i32) -> i32 {
    let bytes = s.as_bytes();
    let sample_str = "cdccsbsg".as_bytes();
    
    for (i, &item) in bytes.iter().enumerate() {
        if item == sample_str[i] {
            return i as i32;
        }
    }
    
    // 0 is 0xdeadbeef
    if bytes[0] == 0 {
        return 0;
    }
    
    return 20 / t1
}



fn main() {
    //let retval = foo();
    //println!("Hello, world!");
}