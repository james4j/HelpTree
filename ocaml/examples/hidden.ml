open Help_tree

let () =
  let opts = discovery_options () in

  let hidden_sub = {
    name = "debug";
    description = "Hidden debug command";
    hidden = true;
    options = [
      { name = "dump"; short = Some 'd'; description = "Dump internal state"; hidden = true; arg = None };
    ];
    arguments = [];
    subcommands = [];
  } in

  let visible_sub = {
    name = "run";
    description = "Run the application";
    hidden = false;
    options = [
      { name = "mode"; short = Some 'm'; description = "Run mode"; hidden = false; arg = Some "MODE" };
    ];
    arguments = [
      { name = "target"; description = "Target to run"; required = true; hidden = false };
    ];
    subcommands = [];
  } in

  let root = {
    name = "hidden";
    description = "An example with hidden commands and options";
    hidden = false;
    options = [
      { name = "verbose"; short = Some 'v'; description = "Verbose output"; hidden = false; arg = None };
      { name = "secret"; short = Some 's'; description = "Hidden secret flag"; hidden = true; arg = Some "TOKEN" };
    ];
    arguments = [
      { name = "input"; description = "Input file"; required = false; hidden = true };
    ];
    subcommands = [visible_sub; hidden_sub];
  } in

  if should_render_tree opts then
    print_string (render opts root)
  else
    Printf.printf "Run with --help-tree to see the command tree.\n"
