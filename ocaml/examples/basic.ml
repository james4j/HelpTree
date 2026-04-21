open Help_tree

let verbose_opt = { name = "verbose"; short = ""; long = "--verbose"; description = "Verbose output"; required = false; takes_value = false; default_val = ""; hidden = false }

let project_list = {
  name = "list"; description = "List all projects";
  options = [verbose_opt]; arguments = []; subcommands = []; hidden = false
}

let arg_name = { name = "NAME"; description = "Project name"; required = true; hidden = false }
let project_create = {
  name = "create"; description = "Create a new project";
  options = [verbose_opt]; arguments = [arg_name]; subcommands = []; hidden = false
}

let project = {
  name = "project"; description = "Manage projects";
  options = [verbose_opt]; arguments = [];
  subcommands = [project_list; project_create]; hidden = false
}

let task_list = {
  name = "list"; description = "List all tasks";
  options = [verbose_opt]; arguments = []; subcommands = []; hidden = false
}

let arg_id = { name = "ID"; description = "Task ID"; required = true; hidden = false }
let task_done = {
  name = "done"; description = "Mark a task as done";
  options = [verbose_opt]; arguments = [arg_id]; subcommands = []; hidden = false
}

let task = {
  name = "task"; description = "Manage tasks";
  options = [verbose_opt]; arguments = [];
  subcommands = [task_list; task_done]; hidden = false
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
  name = "basic"; description = "A basic example CLI with nested subcommands";
  options = root_opts; arguments = [];
  subcommands = [project; task]; hidden = false
}

let () =
  let opts = discovery_options () in
  if should_render_tree opts then
    let config = (try load_config "examples/help-tree.json" with Sys_error _ -> { theme = None }) in
    let opts = apply_config opts config in
    print_string (render opts root)
  else
    Printf.printf "Run with --help-tree to see the command tree.\n"
