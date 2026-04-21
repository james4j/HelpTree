type opt = {
  name : string;
  short : char option;
  description : string;
  hidden : bool;
  arg : string option;
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
  hidden : bool;
  options : opt list;
  arguments : arg list;
  subcommands : cmd list;
}

type discovery_options = {
  help_tree : bool;
  tree_depth : int option;
  tree_ignore : string list;
  tree_all : bool;
  tree_output : string option;
  tree_style : string option;
  tree_color : string option;
}

val discovery_options : unit -> discovery_options

val render_text :
  ?max_depth:int ->
  ?show_hidden:bool ->
  ?path:string list ->
  ?style:string ->
  ?color:string ->
  cmd -> string

val render_json :
  ?max_depth:int ->
  ?show_hidden:bool ->
  ?path:string list ->
  cmd -> string

val should_render_tree : discovery_options -> bool

val render : discovery_options -> cmd -> string
