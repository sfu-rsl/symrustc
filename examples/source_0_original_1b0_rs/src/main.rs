/* The LLVM code obtained from this program would ideally be as close
   as possible to the one obtained from:
   https://github.com/eurecom-s3/symcc/blob/master/sample.cpp
*/

use std::io::{self, BufReader};
use std::io::prelude::*;

fn cmd_root() {
    println!("What is your command?")
}

fn cmd_default(buf: Vec<u8>) {
    print!("Hello, (");
    for c in &buf {
        print!(" {:#04x}", c)
    }
    println!(" ) {:?}!", String::from_utf8_lossy(&buf));
    println!("CMD CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC {:?}", buf); 
}

fn main() -> Result<(), io::Error> {
    let mut buf = vec![];
    let delim = b"\n";
    let root = b"root";
    let root_len = root.len();
    println!("What's your name?");
    match BufReader::new(io::stdin()).read_until(delim[0], &mut buf) {
        Ok(_) => {
            let buf_len = buf.len();
            if buf_len >= root_len
                && buf[0 .. root_len] == *root
                && if buf_len == root_len { true }
                   else if buf_len == root_len + 1 { buf.ends_with(delim) }
                   else { false } {
                println!("What is your command?")
            } else {
                print!("Hello, (");
                for c in &buf {
                    print!(" {:#04x}", c)
                }
                println!(" ) {:?}!", String::from_utf8_lossy(&buf))
            }
            Ok(())
        }
        Err(error) => Err(error)
    }
}
