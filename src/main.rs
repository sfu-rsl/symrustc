/* The LLVM code obtained from this program would ideally be as close
   as possible to the one obtained from:
   https://github.com/eurecom-s3/symcc/blob/master/sample.cpp
*/

use std::io;

fn main() -> Result<(), std::io::Error> {
    let mut name = String::new();
    println!("What's your name?");
    match io::stdin().read_line(&mut name) {
        Ok(_) => {
            match name.trim_end() {
                "root" => println!("What is your command?"),
                name => println!("Hello, {}!", name)
            }
            Ok(())
        }
        Err(error) => Err(error)
    }
}
