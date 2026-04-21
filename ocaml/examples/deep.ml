open Help_tree

let verbose_opt = { name = "verbose"; short = ""; long = "--verbose"; description = "Verbose output"; required = false; takes_value = false; default_val = ""; hidden = false }

let config_get = {
  name = "get"; description = "Get a config value";
  options = [verbose_opt]; arguments = [{ name = "KEY"; description = "Config key"; required = true; hidden = false }];
  subcommands = []; hidden = false
}
let config_set = {
  name = "set"; description = "Set a config value";
  options = [verbose_opt];
  arguments = [
    { name = "KEY"; description = "Config key"; required = true; hidden = false };
    { name = "VALUE"; description = "Config value"; required = true; hidden = false }
  ];
  subcommands = []; hidden = false
}
let config_reload = {
  name = "reload"; description = "Reload configuration";
  options = [verbose_opt]; arguments = []; subcommands = []; hidden = false
}
let config_cmd = {
  name = "config"; description = "Configuration commands";
  options = [verbose_opt]; arguments = [];
  subcommands = [config_get; config_set; config_reload]; hidden = false
}

let db_migrate = { name = "migrate"; description = "Run migrations"; options = []; arguments = []; subcommands = []; hidden = false }
let db_seed = { name = "seed"; description = "Seed the database"; options = []; arguments = []; subcommands = []; hidden = false }
let db_backup = { name = "backup"; description = "Backup the database"; options = []; arguments = []; subcommands = []; hidden = false }
let db = {
  name = "db"; description = "Database commands";
  options = []; arguments = [];
  subcommands = [db_migrate; db_seed; db_backup]; hidden = false
}

let server = {
  name = "server"; description = "Server management";
  options = [verbose_opt]; arguments = [];
  subcommands = [config_cmd; db]; hidden = false
}

let auth_login = { name = "login"; description = "Log in"; options = []; arguments = []; subcommands = []; hidden = false }
let auth_logout = { name = "logout"; description = "Log out"; options = []; arguments = []; subcommands = []; hidden = false }
let auth_whoami = { name = "whoami"; description = "Show current user"; options = []; arguments = []; subcommands = []; hidden = false }
let auth = {
  name = "auth"; description = "Authentication commands";
  options = []; arguments = [];
  subcommands = [auth_login; auth_logout; auth_whoami]; hidden = false
}

let req_get = {
  name = "get"; description = "Send a GET request";
  options = [verbose_opt]; arguments = [{ name = "PATH"; description = "Request path"; required = true; hidden = false }];
  subcommands = []; hidden = false
}
let req_post = {
  name = "post"; description = "Send a POST request";
  options = [verbose_opt]; arguments = [{ name = "PATH"; description = "Request path"; required = true; hidden = false }];
  subcommands = []; hidden = false
}
let request = {
  name = "request"; description = "HTTP request commands";
  options = [verbose_opt]; arguments = [];
  subcommands = [req_get; req_post]; hidden = false
}

let client = {
  name = "client"; description = "Client operations";
  options = [verbose_opt]; arguments = [];
  subcommands = [auth; request]; hidden = false
}

let root_opts = [
  { name = "help-tree"; short = ""; long = "--help-tree"; description = "Print a recursive command map derived from framework metadata"; required = false; takes_value = false; default_val = ""; hidden = false };
  { name = "tree-depth"; short = "-L"; long = "--tree-depth"; description = "Limit --help-tree recursion depth (Unix tree -L style)"; required = false; takes_value = true; default_val = ""; hidden = false };
  { name = "tree-ignore"; short = "-I"; long = "--tree-ignore"; description = "Exclude subtrees/commands from --help-tree output (repeatable)"; required = false; takes_value = true; default_val = ""; hidden = false };
  { name = "tree-all"; short = "-a"; long = "--tree-all"; description = "Include hidden subcommands in --help-tree output"; required = false; takes_value = false; default_val = ""; hidden = false };
  { name = "tree-output"; short = ""; long = "--tree-output"; description = "Output format (text or json)"; required = false; takes_value = true; default_val = ""; hidden = false };
  { name = "tree-style"; short = ""; long = "--tree-style"; description = "Tree text styling mode (rich or plain)"; required = false; takes_value = true; default_val = ""; hidden = false };
  { name = "tree-color"; short = ""; long = "--tree-color"; description = "Tree color mode (auto, always, never)"; required = false; takes_value = true; default_val = ""; hidden = false };
  verbose_opt;
]

let root = {
  name = "deep"; description = "A deeply nested CLI example (3 levels)";
  options = root_opts; arguments = [];
  subcommands = [server; client]; hidden = false
}

let () =
  let opts = discovery_options () in
  if should_render_tree opts then
    let config = (try load_config "examples/help-tree.json" with Sys_error _ -> { theme = None }) in
    let opts = apply_config opts config in
    print_string (render opts root)
  else
    Printf.printf "Run with --help-tree to see the command tree.\n"
