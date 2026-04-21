use clap::{Args, Parser, Subcommand};
use help_tree::{run_for_path, HelpTreeColor, HelpTreeOutputFormat, HelpTreeStyle};

#[derive(Parser)]
#[command(name = "hidden")]
#[command(about = "Example with hidden commands and flags")]
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

    #[arg(long, global = true, hide = true, help = "Enable debug mode")]
    debug: bool,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    #[command(about = "List items")]
    List,
    #[command(about = "Show item details")]
    Show {
        #[arg(help = "Item ID")]
        id: String,
    },
    #[command(about = "Administrative commands", hide = true)]
    Admin(AdminArgs),
}

#[derive(Args)]
struct AdminArgs {
    #[command(subcommand)]
    command: AdminCommands,
}

#[derive(Subcommand)]
enum AdminCommands {
    #[command(about = "List all users")]
    Users,
    #[command(about = "Show system stats")]
    Stats,
    #[command(about = "Secret backdoor", hide = true)]
    Secret,
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if let Some(mut invocation) =
        help_tree::parse_help_tree_invocation(&args[1..]).expect("invalid --help-tree invocation")
    {
        if let Ok(config) = help_tree::load_config("help-tree.toml") {
            help_tree::apply_config(&mut invocation.opts, &config);
        }
        run_for_path::<Cli>(invocation.opts, &invocation.path).unwrap();
        return;
    }

    let cli = Cli::parse();
    match cli.command {
        Commands::List => println!("List"),
        Commands::Show { .. } => println!("Show"),
        Commands::Admin(_) => println!("Admin"),
    }
}
