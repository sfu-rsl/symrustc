//! A libfuzzer-like fuzzer with llmp-multithreading support and restarts
//! The example harness is built for `stb_image`.
use mimalloc::MiMalloc;
#[global_allocator]
static GLOBAL: MiMalloc = MiMalloc;

use std::{
    env,
    path::PathBuf,
    process::{Child, Command, Stdio},
};

use clap::{self, Parser};
use libafl::{
    bolts::{
        current_nanos,
        rands::StdRand,
        shmem::{ShMem, ShMemProvider, StdShMemProvider},
        tuples::{tuple_list, Named},
        AsMutSlice, AsSlice,
    },
    corpus::{Corpus, InMemoryCorpus, OnDiskCorpus},
    events::{setup_restarting_mgr_std, EventConfig},
    executors::{
        command::CommandConfigurator, inprocess::InProcessExecutor, ExitKind, ShadowExecutor,
    },
    feedback_or,
    feedbacks::{CrashFeedback, MaxMapFeedback, TimeFeedback},
    fuzzer::{Fuzzer, StdFuzzer},
    inputs::{BytesInput, HasTargetBytes, Input},
    monitors::MultiMonitor,
    mutators::{
        scheduled::{havoc_mutations, StdScheduledMutator},
        token_mutations::I2SRandReplace,
    },
    observers::{
        concolic::{
            serialization_format::{DEFAULT_ENV_NAME, DEFAULT_SIZE},
            ConcolicObserver,
        },
        StdMapObserver, TimeObserver,
    },
    schedulers::{IndexesLenTimeMinimizerScheduler, QueueScheduler},
    stages::{
        ConcolicTracingStage, ShadowTracingStage, SimpleConcolicMutationalStage,
        StdMutationalStage, TracingStage,
    },
    state::{HasCorpus, StdState},
    Error,
};
use libafl_targets::{
    libfuzzer_initialize, CmpLogObserver, CMPLOG_MAP, EDGES_MAP,
    MAX_EDGES_NUM,
};

#[cfg(all(feature = "std", unix))]
use std::time::Duration;

#[derive(Debug, Parser)]
struct Opt {
    /// This node should do concolic tracing + solving instead of traditional fuzzing
    #[arg(short, long)]
    concolic: bool,
}

pub fn main() {
    // Registry the metadata types used in this fuzzer
    // Needed only on no_std
    //RegistryBuilder::register::<Tokens>();

    let opt = Opt::parse();

    println!(
        "Workdir: {:?}",
        env::current_dir().unwrap().to_string_lossy().to_string()
    );
    fuzz(
        &[PathBuf::from("./corpus")],
        PathBuf::from("./crashes"),
        1337,
        opt.concolic,
    )
    .expect("An error occurred while fuzzing");
}

fn spawn_child0<I: Input + HasTargetBytes>(input: &I) -> Result<Child, Error> {
        let fic_out = env::current_dir().unwrap().join("cur_input").to_string_lossy().to_string();
        //println!("input: {:?} {:?}", fic_out, input);
        input.to_file(&fic_out)?;

        Ok(Command::new("./target_symcc0.out")
            .arg(&fic_out)
            .stdin(Stdio::null())
            // .stdout(Stdio::null())
            // .stderr(Stdio::null())
            .env("SYMCC_NO_SYMBOLIC_INPUT", "yes")
            .spawn()
            .expect("failed to start process"))
}

fn eprint_input_exit<I: Input + HasTargetBytes>(input: &I) {
    eprint!("error: on");
    for c in &input.target_bytes() {
        eprint!(" {:#04x}", c)
    }
    eprint!(", exit ");
}

/// Coverage map with explicit assignments due to the lack of instrumentation
static mut SIGNALS: [u8; 16] = [0; 16];

/// Assign a signal to the signals map
fn signals_set(idx: usize) {
    unsafe { SIGNALS[idx] = 1 };
}

/// The actual fuzzer
fn fuzz(
    corpus_dirs: &[PathBuf],
    objective_dir: PathBuf,
    broker_port: u16,
    concolic: bool,
) -> Result<(), Error> {
    // 'While the stats are state, they are usually used in the broker - which is likely never restarted
    let monitor = MultiMonitor::new(|s| println!("{}", s));

    // The restarting state will spawn the same process again as child, then restarted it each time it crashes.
    let (state, mut restarting_mgr) =
        match setup_restarting_mgr_std(monitor, broker_port, EventConfig::from_name("default")) {
            Ok(res) => res,
            Err(err) => match err {
                Error::ShuttingDown => {
                    return Ok(());
                }
                _ => {
                    panic!("Failed to setup the restarter: {}", err);
                }
            },
        };

    // Create an observation channel using the coverage map
    // We don't use the hitcounts (see the Cargo.toml, we use pcguard_edges)
    let edges = unsafe { &mut EDGES_MAP[0..MAX_EDGES_NUM] };
    let edges_observer = StdMapObserver::new("edges", edges);

    // Create an observation channel using the signals map
    let observer = StdMapObserver::new("signals", unsafe { &mut SIGNALS });

    // Create an observation channel to keep track of the execution time
    let time_observer = TimeObserver::new("time");

    let cmplog = unsafe { &mut CMPLOG_MAP };
    let cmplog_observer = CmpLogObserver::new("cmplog", cmplog, true);

    // Feedback to rate the interestingness of an input
    // This one is composed by two Feedbacks in OR
    let mut feedback = feedback_or!(
        // New maximization map feedback
        MaxMapFeedback::new_tracking(&observer, true, false),
        // Time feedback, this one does not need a feedback state
        TimeFeedback::new_with_observer(&time_observer)
    );

    // A feedback to choose if an input is a solution or not
    let mut objective = CrashFeedback::new();

    // If not restarting, create a State from scratch
    let mut state = state.unwrap_or_else(|| {
        StdState::new(
            // RNG
            StdRand::with_seed(current_nanos()),
            // Corpus that will be evolved, we keep it in memory for performance
            InMemoryCorpus::new(),
            // Corpus in which we store solutions (crashes in this example),
            // on disk so the user can get them after stopping the fuzzer
            OnDiskCorpus::new(objective_dir).unwrap(),
            // States of the feedbacks.
            // The feedbacks can report the data that should persist in the State.
            &mut feedback,
            // Same for objective feedbacks
            &mut objective,
        )
        .unwrap()
    });

    println!("We're a client, let's fuzz :)");

    // A minimization+queue policy to get testcasess from the corpus
    let scheduler = IndexesLenTimeMinimizerScheduler::new(QueueScheduler::new());

    // A fuzzer with feedbacks and a corpus scheduler
    let mut fuzzer = StdFuzzer::new(scheduler, feedback, objective);

    // The wrapped harness function, calling out to the LLVM-style harness
    let mut harness = |input: &BytesInput| {
        use std::os::unix::prelude::ExitStatusExt;
        use wait_timeout::ChildExt;
        use libafl::inputs::HasBytesVec;
        
        println!("ZZZZZZZZZZZZZZZZZZZZZZZ");
        let buf = input.bytes();
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
        signals_set(0);
            if buf_len > root1_len && buf[0 .. root1_len] == *root1 {
        signals_set(1);
                if buf_len > root2_len && buf[0 .. root2_len] == *root2 {
        signals_set(2);
                    if buf_len > root3a_len && buf[0 .. root3a_len] == *root3a {
        signals_set(3);
                        if buf[0 .. root4a_len] == *root4a
                            && if buf_len == root4a_len { true }
                               else if buf_len == root4a_len + 1 { buf.ends_with(delim) }
                               else { false } {
        //signals_set(4);
                            print!("What is your command (A)? (");
                            for c in buf {
                                print!(" {:#04x}", c)
                            }
                            println!(" )");
                            //panic!("Artificial bug (A)")
        ExitKind::Crash
                        } else {
        //signals_set(5);
                            print!("Hello 4a, (");
                            for c in buf {
                                print!(" {:#04x}", c)
                            }
                            println!(" ) {:?}!", String::from_utf8_lossy(&buf));
        ExitKind::Ok
                        }
                    } else {
        signals_set(6);
                        if buf_len > root3b_len && buf[0 .. root3b_len] == *root3b {
        signals_set(7);
                            if buf[0 .. root4b_len] == *root4b
                                && if buf_len == root4b_len { true }
                                   else if buf_len == root4b_len + 1 { buf.ends_with(delim) }
                                   else { false } {
        //signals_set(8);
                                print!("What is your command (B)? (");
                                for c in buf {
                                    print!(" {:#04x}", c)
                                }
                                println!(" )");
                                //panic!("Artificial bug (B)")
        ExitKind::Crash
                            } else {
        //signals_set(9);
                                print!("Hello 4b, (");
                                for c in buf {
                                    print!(" {:#04x}", c)
                                }
                                println!(" ) {:?}!", String::from_utf8_lossy(&buf));
        ExitKind::Ok
                            }
                        } else {
        signals_set(10);
                            print!("Hello 3, (");
                            for c in buf {
                                print!(" {:#04x}", c)
                            }
                            println!(" ) {:?}!", String::from_utf8_lossy(&buf));
        ExitKind::Ok
                        }
                    }
                } else {
        signals_set(11);
                    print!("Hello 2, (");
                    for c in buf {
                        print!(" {:#04x}", c)
                    }
                    println!(" ) {:?}!", String::from_utf8_lossy(&buf));
        ExitKind::Ok
                }
            } else {
        signals_set(12);
                print!("Hello 1, (");
                for c in buf {
                    print!(" {:#04x}", c)
                }
                println!(" ) {:?}!", String::from_utf8_lossy(&buf));
        ExitKind::Ok
            }
    };

    // Create the executor for an in-process function with just one observer for edge coverage
    let mut executor = ShadowExecutor::new(
        InProcessExecutor::new(
            &mut harness,
            tuple_list!(observer, time_observer),
            &mut fuzzer,
            &mut state,
            &mut restarting_mgr,
        )?,
        tuple_list!(cmplog_observer),
    );

    // The actual target run starts here.
    // Call LLVMFUzzerInitialize() if present.
    let args: Vec<String> = env::args().collect();
    if libfuzzer_initialize(&args) == -1 {
        println!("Warning: LLVMFuzzerInitialize failed with -1")
    }

    // In case the corpus is empty (on first run), reset
    if state.corpus().count() < 1 {
        println!("====================1");
        state
            .load_initial_inputs_forced(
                &mut fuzzer,
                &mut executor,
                &mut restarting_mgr,
                &corpus_dirs,
            )
            .unwrap_or_else(|_| panic!("Failed to load initial corpus at {:?}", &corpus_dirs));
        println!("We imported {} inputs from disk.", state.corpus().count());
    }

    // Setup a tracing stage in which we log comparisons
    let tracing = ShadowTracingStage::new(&mut executor);

    // Setup a randomic Input2State stage
    let i2s = StdMutationalStage::new(StdScheduledMutator::new(tuple_list!(I2SRandReplace::new())));

    // Setup a basic mutator
    let mutator = StdScheduledMutator::new(havoc_mutations());
    let mutational = StdMutationalStage::new(mutator);

    if concolic {
        // The shared memory for the concolic runtime to write its trace to
        let mut concolic_shmem = StdShMemProvider::new()
            .unwrap()
            .new_shmem(DEFAULT_SIZE)
            .unwrap();
        concolic_shmem.write_to_env(DEFAULT_ENV_NAME).unwrap();

        // The concolic observer observers the concolic shared memory map.
        let concolic_observer =
            ConcolicObserver::new("concolic".to_string(), concolic_shmem.as_mut_slice());

        let concolic_observer_name = concolic_observer.name().to_string();

        // The order of the stages matter!
        let mut stages = tuple_list!(
            // Create a concolic trace
            ConcolicTracingStage::new(
                TracingStage::new(
                    MyCommandConfigurator::default().into_executor(tuple_list!(concolic_observer))
                ),
                concolic_observer_name,
            ),
            // Use the concolic trace for z3-based solving
            SimpleConcolicMutationalStage::default(),
        );

        println!("====================0");
        fuzzer.fuzz_loop(&mut stages, &mut executor, &mut state, &mut restarting_mgr)?;
    } else {
        // The order of the stages matter!
        let mut stages = tuple_list!(tracing, i2s, mutational);

        fuzzer.fuzz_loop(&mut stages, &mut executor, &mut state, &mut restarting_mgr)?;
    }

    // Never reached
    Ok(())
}

#[derive(Default, Debug)]
pub struct MyCommandConfigurator;

impl CommandConfigurator for MyCommandConfigurator {
    fn spawn_child<I: Input + HasTargetBytes>(&mut self, input: &I) -> Result<Child, Error> {
        let fic_out = env::current_dir().unwrap().join("cur_input").to_string_lossy().to_string();
        //println!("input: {:?} {:?}", fic_out, input);
        input.to_file(&fic_out)?;

        Ok(Command::new("./target_symcc.out")
            .arg(&fic_out)
            .stdin(Stdio::null())
            // .stdout(Stdio::null())
            // .stderr(Stdio::null())
            .env("SYMCC_INPUT_FILE", &fic_out)
            .spawn()
            .expect("failed to start process"))
    }
}
