/* The LLVM code obtained from this program would ideally be as close
   as possible to the one obtained from:
   https://github.com/eurecom-s3/symcc/blob/master/sample.cpp
*/

use std::io::{self, BufReader};
use std::io::prelude::*;

fn main() -> Result<(), io::Error> {
    let mut buf = vec![];

    println!("What's your name?");
    match BufReader::new(io::stdin()).read_until(b'\n', &mut buf) {
        Ok(_) => {
            if buf == b"root\n" {
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
