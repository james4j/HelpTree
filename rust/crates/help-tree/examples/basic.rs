use clap::{Args, Parser, Subcommand};
use help_tree::{run_for_path, HelpTreeColor, HelpTreeOutputFormat, HelpTreeStyle};

#[derive(Parser)]
#[command(name = "basic")]
#[command(about = "A basic example CLI with nested subcommands")]
struct Cli {
    #[arg(long, global = true, help = "Verbose output")]
    verbose: bool,

    #[arg(
        long = "help-tree",
        help = "Print a recursive command map derived from framework metadata"
    )]
    help_tree: bool,

    #[arg(
        long = "tree-depth",
        short = 'L',
        help = "Limit --help-tree recursion depth"
    )]
    tree_depth: Option<usize>,

    #[arg(
        long = "tree-ignore",
        short = 'I',
        help = "Exclude subtrees/commands from --help-tree output"
    )]
    tree_ignore: Vec<String>,

    #[arg(
        long = "tree-all",
        short = 'a',
        help = "Include hidden subcommands in --help-tree output"
    )]
    tree_all: bool,

    #[arg(
        long = "tree-output",
        help = "Output format (text or json)",
        value_enum
    )]
    tree_output: Option<HelpTreeOutputFormat>,

    #[arg(
        long = "tree-style",
        help = "Tree text styling mode (rich or plain)",
        value_enum
    )]
    tree_style: Option<HelpTreeStyle>,

    #[arg(
        long = "tree-color",
        help = "Tree color mode (auto, always, never)",
        value_enum
    )]
    tree_color: Option<HelpTreeColor>,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    #[command(about = "Manage projects")]
    Project(ProjectArgs),
    #[command(about = "Manage tasks")]
    Task(TaskArgs),
}

#[derive(Args)]
struct ProjectArgs {
    #[command(subcommand)]
    command: ProjectCommands,
}

#[derive(Subcommand)]
enum ProjectCommands {
    #[command(about = "List all projects")]
    List,
    #[command(about = "Create a new project")]
    Create {
        #[arg(help = "Project name")]
        name: String,
    },
}

#[derive(Args)]
struct TaskArgs {
    #[command(subcommand)]
    command: TaskCommands,
}

#[derive(Subcommand)]
enum TaskCommands {
    #[command(about = "List all tasks")]
    List,
    #[command(about = "Mark a task as done")]
    Done {
        #[arg(help = "Task ID")]
        id: u32,
    },
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if let Some(mut invocation) =
        help_tree::parse_help_tree_invocation(&args[1..]).expect("invalid --help-tree invocation")
    {
        // Load per-project theme config if present
        if let Ok(config) = help_tree::load_config("help-tree.toml") {
            help_tree::apply_config(&mut invocation.opts, &config);
        }
        run_for_path::<Cli>(invocation.opts, &invocation.path).unwrap();
        return;
    }

    let cli = Cli::parse();
    match cli.command {
        Commands::Project(_) => println!("Project command"),
        Commands::Task(_) => println!("Task command"),
    }
}
