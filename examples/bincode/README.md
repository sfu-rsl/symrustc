This fuzz folder is supposed to be created by running `cargo fuzz init` in the root folder of `bincode`.

The aim is to regenerate the error fixed in bincode-org/bincode#465. So, we checkout at [v2.0.0-beta.0](https://github.com/bincode-org/bincode/tree/v2.0.0-beta.0), where the problem is not fixed (and no fuzzer folder exists neither).

If you are interested in performing the fuzzing using libAFL and SymRustC take a look at [this gist](https://gist.github.com/momvart/4c10d5856ec45e4364780d79fbf0d181) which demonstrates how to integrate them with the `libfuzzer_rust_concolic_instance`,
