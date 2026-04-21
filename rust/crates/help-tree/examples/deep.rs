use clap::{Args, Parser, Subcommand};
use help_tree::run_for_path;

#[derive(Parser)]
#[command(name = "deep")]
#[command(about = "A deeply nested CLI example (3 levels)")]
struct Cli {
    #[arg(long, global = true, help = "Verbose output")]
    verbose: bool,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    #[command(about = "Server management")]
    Server(ServerArgs),
    #[command(about = "Client operations")]
    Client(ClientArgs),
}

#[derive(Args)]
struct ServerArgs {
    #[command(subcommand)]
    command: ServerCommands,
}

#[derive(Subcommand)]
enum ServerCommands {
    #[command(about = "Configuration commands")]
    Config(ConfigArgs),
    #[command(about = "Database commands")]
    Db(DbArgs),
}

#[derive(Args)]
struct ConfigArgs {
    #[command(subcommand)]
    command: ConfigCommands,
}

#[derive(Subcommand)]
enum ConfigCommands {
    #[command(about = "Get a config value")]
    Get {
        #[arg(help = "Config key")]
        key: String,
    },
    #[command(about = "Set a config value")]
    Set {
        #[arg(help = "Config key")]
        key: String,
        #[arg(help = "Config value")]
        value: String,
    },
    #[command(about = "Reload configuration")]
    Reload,
}

#[derive(Args)]
struct DbArgs {
    #[command(subcommand)]
    command: DbCommands,
}

#[derive(Subcommand)]
enum DbCommands {
    #[command(about = "Run migrations")]
    Migrate,
    #[command(about = "Seed the database")]
    Seed,
    #[command(about = "Backup the database")]
    Backup,
}

#[derive(Args)]
struct ClientArgs {
    #[command(subcommand)]
    command: ClientCommands,
}

#[derive(Subcommand)]
enum ClientCommands {
    #[command(about = "Authentication commands")]
    Auth(AuthArgs),
    #[command(about = "HTTP request commands")]
    Request(RequestArgs),
}

#[derive(Args)]
struct AuthArgs {
    #[command(subcommand)]
    command: AuthCommands,
}

#[derive(Subcommand)]
enum AuthCommands {
    #[command(about = "Log in")]
    Login,
    #[command(about = "Log out")]
    Logout,
    #[command(about = "Show current user")]
    Whoami,
}

#[derive(Args)]
struct RequestArgs {
    #[command(subcommand)]
    command: RequestCommands,
}

#[derive(Subcommand)]
enum RequestCommands {
    #[command(about = "Send a GET request")]
    Get {
        #[arg(help = "URL path")]
        path: String,
    },
    #[command(about = "Send a POST request")]
    Post {
        #[arg(help = "URL path")]
        path: String,
    },
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
        Commands::Server(_) => println!("Server command"),
        Commands::Client(_) => println!("Client command"),
    }
}
