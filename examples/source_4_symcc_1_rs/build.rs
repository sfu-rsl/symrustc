extern crate cc;

fn main() {
    cc::Build::new()
        .compiler("clang") // Semantically: should symlink to symcc to enable concolic annotation.
                           // Syntactically: should contain the string "clang" for the custom compiler to be classified as a 'clang' type of compiler.
        .file("src/memcpy.c")
        .compile("memcpy");
}
