use clap::{Args, Parser, Subcommand};
use help_tree::run_for_path;

#[derive(Parser)]
#[command(name = "hidden")]
#[command(about = "Example with hidden commands and flags")]
struct Cli {
    #[arg(long, global = true, help = "Verbose output")]
    verbose: bool,

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
