fn main() {
    let mut a = 31;
    if std::env::args().len() == 1 {
        a = 1;
    };
    std::process::exit(a)
}
