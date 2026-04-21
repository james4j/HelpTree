open Help_tree

let verbose_opt = { name = "verbose"; short = ""; long = "--verbose"; description = "Verbose output"; required = false; takes_value = false; default_val = ""; hidden = false }
let debug_opt = { name = "debug"; short = ""; long = "--debug"; description = "Enable debug mode"; required = false; takes_value = false; default_val = ""; hidden = true }

let list_cmd = { name = "list"; description = "List items"; options = []; arguments = []; subcommands = []; hidden = false }
let show_cmd = {
  name = "show"; description = "Show item details";
  options = []; arguments = [{ name = "ID"; description = "Item ID"; required = true; hidden = false }];
  subcommands = []; hidden = false
}

let admin_users = { name = "users"; description = "List all users"; options = []; arguments = []; subcommands = []; hidden = false }
let admin_stats = { name = "stats"; description = "Show system stats"; options = []; arguments = []; subcommands = []; hidden = false }
let admin_secret = { name = "secret"; description = "Secret backdoor"; options = []; arguments = []; subcommands = []; hidden = false }
let admin = {
  name = "admin"; description = "Administrative commands";
  options = []; arguments = [];
  subcommands = [admin_users; admin_stats; admin_secret]; hidden = true
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
  debug_opt;
]

let root = {
  name = "hidden"; description = "An example with hidden commands and flags";
  options = root_opts; arguments = [];
  subcommands = [list_cmd; show_cmd; admin]; hidden = false
}

let () =
  let opts = discovery_options () in
  if should_render_tree opts then
    let config = (try load_config "examples/help-tree.json" with Sys_error _ -> { theme = None }) in
    let opts = apply_config opts config in
    print_string (render opts root)
  else
    Printf.printf "Run with --help-tree to see the command tree.\n"
