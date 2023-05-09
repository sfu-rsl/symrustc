This fuzz folder is supposed to be created by running `cargo fuzz init` in the root folder of `bincode`.

The aim is to regenerate the error fixed in bincode-org/bincode#465. So, we checkout at [v2.0.0-beta.0](https://github.com/bincode-org/bincode/tree/v2.0.0-beta.0), where the problem is not fixed (and no fuzzer folder exists neither).
