open Help_tree

let () =
  let opts = discovery_options () in

  let serve_cmd = {
    name = "serve";
    description = "Start the server";
    hidden = false;
    options = [
      { name = "port"; short = Some 'p'; description = "Port to listen on"; hidden = false; arg = Some "PORT" };
      { name = "host"; short = Some 'h'; description = "Host to bind"; hidden = false; arg = Some "HOST" };
    ];
    arguments = [
      { name = "directory"; description = "Directory to serve"; required = false; hidden = false };
    ];
    subcommands = [];
  } in

  let init_cmd = {
    name = "init";
    description = "Initialize project";
    hidden = false;
    options = [
      { name = "force"; short = Some 'f'; description = "Overwrite existing"; hidden = false; arg = None };
    ];
    arguments = [
      { name = "name"; description = "Project name"; required = true; hidden = false };
    ];
    subcommands = [];
  } in

  let root = {
    name = "basic";
    description = "A basic example application";
    hidden = false;
    options = [
      { name = "verbose"; short = Some 'v'; description = "Enable verbose output"; hidden = false; arg = None };
      { name = "output"; short = Some 'o'; description = "Output file"; hidden = false; arg = Some "FILE" };
    ];
    arguments = [
      { name = "input"; description = "Input file"; required = true; hidden = false };
    ];
    subcommands = [serve_cmd; init_cmd];
  } in

  if should_render_tree opts then
    print_string (render opts root)
  else
    Printf.printf "Run with --help-tree to see the command tree.\n"
