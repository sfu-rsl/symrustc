/* The LLVM code obtained from this program would ideally be as close
   as possible to the one obtained from:
   https://github.com/eurecom-s3/symcc/blob/master/sample.cpp
*/

use std::io;
use std::env;
use std::fs;

fn main() -> Result<(), io::Error> {
    let args: Vec<String> = env::args().collect();
    match args.get(1) {
        Some(file) => {
            let buf = fs::read(file).expect("Error reading the file");
            let delim = b"\n";
            let root = b"root";
            let root_len = root.len();
            println!("What's your name?");
            let buf_len = buf.len();
            if buf_len >= root_len
                && buf[0 .. root_len] == *root
                && if buf_len == root_len { true }
                   else if buf_len == root_len + 1 { buf.ends_with(delim) }
                   else { false } {
                print!("What is your command? (");
                for c in &buf {
                    print!(" {:#04x}", c)
                }
                println!(" )");
                panic!("Artificial bug")
            } else {
                print!("Hello, (");
                for c in &buf {
                    print!(" {:#04x}", c)
                }
                println!(" ) {:?}!", String::from_utf8_lossy(&buf))
            }
            Ok(())
        }
        None => Ok(())
    }
}
