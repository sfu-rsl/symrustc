/* The LLVM code obtained from this program would ideally be as close
   as possible to the one obtained from:
   https://github.com/eurecom-s3/symcc/blob/master/sample.cpp
*/

use std::ffi::OsString;
use std::fs;
use std::io::Error;

fn main00(mut args : impl Iterator<Item = OsString>) -> Result<(), Error> {
    match args.next() {
        Some(_) => {
    match args.next() {
        Some(file) => {
            let buf = fs::read(file).expect("Error reading the file");
            let buf_len = buf.len();
            let delim = b"\n";
            println!("What's your name?");
            let root1 = b"r";
            let root1_len = root1.len();
            let root2 = b"ro";
            let root2_len = root2.len();
            let root3a = b"roo";
            let root3a_len = root3a.len();
            let root4a = b"root";
            let root4a_len = root4a.len();
            let root3b = b"roa";
            let root3b_len = root3b.len();
            let root4b = b"road";
            let root4b_len = root4b.len();
            if buf_len > root1_len && buf[0 .. root1_len] == *root1 {
                if buf_len > root2_len && buf[0 .. root2_len] == *root2 {
                    if buf_len > root3a_len && buf[0 .. root3a_len] == *root3a {
                        if buf[0 .. root4a_len] == *root4a
                            && if buf_len == root4a_len { true }
                               else if buf_len == root4a_len + 1 { buf.ends_with(delim) }
                               else { false } {
                            print!("What is your command (A)? (");
                            for c in &buf {
                                print!(" {:#04x}", c)
                            }
                            println!(" )");
                            panic!("Artificial bug (A)")
                        } else {
                            print!("Hello 4a, (");
                            for c in &buf {
                                print!(" {:#04x}", c)
                            }
                            println!(" ) {:?}!", String::from_utf8_lossy(&buf))
                        }
                    } else {
                        if buf_len > root3b_len && buf[0 .. root3b_len] == *root3b {
                            if buf[0 .. root4b_len] == *root4b
                                && if buf_len == root4b_len { true }
                                   else if buf_len == root4b_len + 1 { buf.ends_with(delim) }
                                   else { false } {
                                print!("What is your command (B)? (");
                                for c in &buf {
                                    print!(" {:#04x}", c)
                                }
                                println!(" )");
                                panic!("Artificial bug (B)")
                            } else {
                                print!("Hello 4b, (");
                                for c in &buf {
                                    print!(" {:#04x}", c)
                                }
                                println!(" ) {:?}!", String::from_utf8_lossy(&buf))
                            }
                        } else {
                            print!("Hello 3, (");
                            for c in &buf {
                                print!(" {:#04x}", c)
                            }
                            println!(" ) {:?}!", String::from_utf8_lossy(&buf))
                        }
                    }
                } else {
                    print!("Hello 2, (");
                    for c in &buf {
                        print!(" {:#04x}", c)
                    }
                    println!(" ) {:?}!", String::from_utf8_lossy(&buf))
                }
            } else {
                print!("Hello 1, (");
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
        None => Ok(())
    }
}

pub fn main0(args : Vec<OsString>) -> Result<(), Error> {
    main00(args.iter().cloned())
}
