type opt = {
  name : string;
  short : string;
  long : string;
  description : string;
  required : bool;
  takes_value : bool;
  default_val : string;
  hidden : bool;
}

type arg = {
  name : string;
  description : string;
  required : bool;
  hidden : bool;
}

type cmd = {
  name : string;
  description : string;
  options : opt list;
  arguments : arg list;
  subcommands : cmd list;
  hidden : bool;
}

type discovery_options = {
  help_tree : bool;
  tree_depth : int option;
  tree_ignore : string list;
  tree_all : bool;
  tree_output : string option;
  tree_style : string option;
  tree_color : string option;
  path : string list;
}

val discovery_options : unit -> discovery_options
val should_render_tree : discovery_options -> bool
val render : discovery_options -> cmd -> string
