use clap::{Args, Parser, Subcommand};
use help_tree::run_with_help_tree;

#[derive(Parser)]
#[command(name = "hidden")]
#[command(about = "Example with hidden commands and flags")]
struct Cli {
    #[arg(long, global = true, help = "Verbose output")]
    verbose: bool,

    #[command(flatten)]
    help_tree: help_tree::HelpTreeArgs,

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
    run_with_help_tree::<Cli>(|| {
        let cli = Cli::parse();
        match cli.command {
            Commands::List => println!("List"),
            Commands::Show { .. } => println!("Show"),
            Commands::Admin(_) => println!("Admin"),
        }
    });
}
