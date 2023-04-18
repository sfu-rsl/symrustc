// build.rs

use std::{
    env,
    io::{stdout, Write},
    path::{Path, PathBuf},
    process::exit,
};

use which::which;

fn build_dep_check(tools: &[&str]) {
    for tool in tools {
        println!("Checking for build tool {}...", tool);

        if let Ok(path) = which(tool) {
            println!("Found build tool {}", path.to_str().unwrap());
        } else {
            println!("ERROR: missing build tool {}", tool);
            exit(1);
        };
    }
}

fn main() {
    let out_path = PathBuf::from(&env::var_os("OUT_DIR").unwrap());

    build_dep_check(&["clang", "clang++"]);

    // Enforce clang for its -fsanitize-coverage support.
    std::env::set_var("CC", "clang");
    std::env::set_var("CXX", "clang++");

    println!(
        "cargo:rustc-link-search=native={}",
        &out_path.to_string_lossy()
    );

    let symcc_dir = clone_and_build_symcc(&out_path);

    let runtime_dir = std::env::var("CARGO_TARGET_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            std::env::current_dir()
                .unwrap()
                .join("..")
                .join("runtime")
                .join("target")
        })
        .join(std::env::var("PROFILE").unwrap());

    if !runtime_dir.join("libSymRuntime.so").exists() {
        println!("cargo:warning=Runtime not found. Build it first.");
        exit(1);
    }

    // SymCC.
    std::env::set_var("CC", symcc_dir.join("symcc"));
    std::env::set_var("CXX", symcc_dir.join("sym++"));
    std::env::set_var("SYMCC_RUNTIME_DIR", runtime_dir);

    println!("cargo:rerun-if-changed=build.rs");
}

fn clone_and_build_symcc(out_path: &Path) -> PathBuf {
    let repo_dir = out_path.join("libafl_symcc_src");
    if !repo_dir.exists() {
        symcc_libafl::clone_symcc(&repo_dir);
    }

    symcc_libafl::build_symcc(&repo_dir)
}
