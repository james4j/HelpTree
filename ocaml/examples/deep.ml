open Help_tree

let () =
  let opts = discovery_options () in

  let start_cmd = {
    name = "start";
    description = "Start a service";
    hidden = false;
    options = [
      { name = "foreground"; short = Some 'f'; description = "Run in foreground"; hidden = false; arg = None };
    ];
    arguments = [];
    subcommands = [];
  } in

  let stop_cmd = {
    name = "stop";
    description = "Stop a service";
    hidden = false;
    options = [
      { name = "force"; short = None; description = "Force stop"; hidden = false; arg = None };
    ];
    arguments = [
      { name = "service"; description = "Service name"; required = true; hidden = false };
    ];
    subcommands = [];
  } in

  let service_cmd = {
    name = "service";
    description = "Manage services";
    hidden = false;
    options = [];
    arguments = [];
    subcommands = [start_cmd; stop_cmd];
  } in

  let list_cmd = {
    name = "list";
    description = "List items";
    hidden = false;
    options = [
      { name = "format"; short = None; description = "Output format"; hidden = false; arg = Some "FMT" };
    ];
    arguments = [];
    subcommands = [];
  } in

  let root = {
    name = "deep";
    description = "A deeply nested example application";
    hidden = false;
    options = [
      { name = "config"; short = Some 'c'; description = "Config file"; hidden = false; arg = Some "PATH" };
    ];
    arguments = [
      { name = "command"; description = "Command to run"; required = false; hidden = false };
    ];
    subcommands = [service_cmd; list_cmd];
  } in

  if should_render_tree opts then
    print_string (render opts root)
  else
    Printf.printf "Run with --help-tree to see the command tree.\n"
