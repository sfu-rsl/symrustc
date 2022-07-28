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
            let r = buf_len >= root_len; 
            println!("ASSI 00000000000000000000000000000000000000000000000000 {:?}", buf); 
            if r { 
                let r = buf[0 .. root_len] == *root; 
                println!("ASSI 11111111111111111111111111111111111111111111111111 {:?}", buf); 
                if r { 
                    let r = buf_len == root_len; 
                    println!("ASSI 22222222222222222222222222222222222222222222222222 {:?}", buf); 
                    if r { 
                        cmd_root(); 
                    } else { 
                    println!("ELSE 33333333333333333333333333333333333333333333333333 {:?}", buf); 
                        let r = buf_len == root_len + 1; 
                        println!("ASSI 44444444444444444444444444444444444444444444444444 {:?}", buf); 
                        if r { 
                            let r = buf.ends_with(delim); 
                            println!("ASSI 55555555555555555555555555555555555555555555555555 {:?}", buf); 
                            if r { 
                                cmd_root(); 
                            } else { 
                            println!("ELSE 66666666666666666666666666666666666666666666666666 {:?}", buf); 
                                cmd_default(buf); 
                            } 
                        } else { 
                        println!("ELSE 77777777777777777777777777777777777777777777777777 {:?}", buf); 
                            cmd_default(buf); 
                        } 
                    } 
                } else { 
                println!("ELSE 88888888888888888888888888888888888888888888888888 {:?}", buf); 
                    cmd_default(buf); 
                } 
            } else { 
            println!("ELSE 99999999999999999999999999999999999999999999999999 {:?}", buf); 
                cmd_default(buf); 
            }
            Ok(())
        }
        Err(error) => Err(error)
    }
}
