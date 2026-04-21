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

type theme_token = {
  emphasis : string;
  color_hex : string option;
}

type theme = {
  command : theme_token;
  options : theme_token;
  description : theme_token;
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
  theme : theme;
}

type config_file = {
  theme : theme option;
}

val discovery_options : unit -> discovery_options
val should_render_tree : discovery_options -> bool
val render : discovery_options -> cmd -> string
val load_config : string -> config_file
val apply_config : discovery_options -> config_file -> discovery_options
val verbose_opt : opt
