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

let rec parse_args args acc =
  match args with
  | [] -> acc
  | "--help-tree" :: rest ->
      parse_args rest { acc with help_tree = true }
  | "-L" :: value :: rest
  | "--tree-depth" :: value :: rest ->
      let depth = try Some (int_of_string value) with Failure _ -> None in
      parse_args rest { acc with tree_depth = depth }
  | "-I" :: value :: rest
  | "--tree-ignore" :: value :: rest ->
      parse_args rest { acc with tree_ignore = value :: acc.tree_ignore }
  | "-a" :: rest
  | "--tree-all" :: rest ->
      parse_args rest { acc with tree_all = true }
  | "--tree-output" :: value :: rest ->
      parse_args rest { acc with tree_output = Some value }
  | "--tree-style" :: value :: rest ->
      parse_args rest { acc with tree_style = Some value }
  | "--tree-color" :: value :: rest ->
      parse_args rest { acc with tree_color = Some value }
  | arg :: rest when String.length arg > 13 && String.sub arg 0 13 = "--tree-depth=" ->
      let value = String.sub arg 13 (String.length arg - 13) in
      let depth = try Some (int_of_string value) with Failure _ -> None in
      parse_args rest { acc with tree_depth = depth }
  | arg :: rest when String.length arg > 14 && String.sub arg 0 14 = "--tree-ignore=" ->
      let value = String.sub arg 14 (String.length arg - 14) in
      parse_args rest { acc with tree_ignore = value :: acc.tree_ignore }
  | arg :: rest when String.length arg > 14 && String.sub arg 0 14 = "--tree-output=" ->
      let value = String.sub arg 14 (String.length arg - 14) in
      parse_args rest { acc with tree_output = Some value }
  | arg :: rest when String.length arg > 13 && String.sub arg 0 13 = "--tree-style=" ->
      let value = String.sub arg 13 (String.length arg - 13) in
      parse_args rest { acc with tree_style = Some value }
  | arg :: rest when String.length arg > 13 && String.sub arg 0 13 = "--tree-color=" ->
      let value = String.sub arg 13 (String.length arg - 13) in
      parse_args rest { acc with tree_color = Some value }
  | _ :: rest -> parse_args rest acc

let discovery_options () =
  let defaults = {
    help_tree = false;
    tree_depth = None;
    tree_ignore = [];
    tree_all = false;
    tree_output = None;
    tree_style = None;
    tree_color = None;
  } in
  parse_args (List.tl (Array.to_list Sys.argv)) defaults

let should_render_tree opts = opts.help_tree

let is_tty () =
  try
    let stat = Unix.stat "/dev/stdout" in
    stat.Unix.st_kind = Unix.S_CHR
  with _ -> false

let use_color opts =
  match opts.tree_color with
  | Some "always" -> true
  | Some "never" -> false
  | _ -> is_tty ()

let ansi color_code s =
  "\027[" ^ color_code ^ "m" ^ s ^ "\027[0m"

let colorize opts color s =
  if use_color opts then ansi color s else s

let escape_json s =
  let buf = Buffer.create (String.length s * 2) in
  String.iter (function
    | '"' -> Buffer.add_string buf "\\\""
    | '\\' -> Buffer.add_string buf "\\\\"
    | '\b' -> Buffer.add_string buf "\\b"
    | '\n' -> Buffer.add_string buf "\\n"
    | '\r' -> Buffer.add_string buf "\\r"
    | '\t' -> Buffer.add_string buf "\\t"
    | c ->
        if Char.code c < 0x20 then
          Buffer.add_string buf (Printf.sprintf "\\u%04x" (Char.code c))
        else
          Buffer.add_char buf c
  ) s;
  Buffer.contents buf

let join sep lst =
  let rec aux acc = function
    | [] -> acc
    | [x] -> acc ^ x
    | x :: xs -> aux (acc ^ x ^ sep) xs
  in
  aux "" lst

let rec filter_ignored ignore_list cmds =
  List.filter (fun c -> not (List.mem c.name ignore_list)) cmds

let rec find_path path cmds =
  match path with
  | [] -> cmds
  | name :: rest ->
      let found = List.find_opt (fun c -> c.name = name) cmds in
      match found with
      | Some c -> [c]
      | None -> []

let rec render_text_cmd ?(max_depth = -1) ?(show_hidden = false) ?(path = [])
    ?(style = "default") ?(color = "auto") opts prefix is_last buf cmd =
  let depth = String.length prefix / 2 in
  if max_depth >= 0 && depth > max_depth then ()
  else if not show_hidden && cmd.hidden then ()
  else begin
    let branch = if is_last then "└─ " else "├─ " in
    let line = prefix ^ branch ^ cmd.name in
    let colored_line = colorize opts "1;36" line in
    Buffer.add_string buf colored_line;
    Buffer.add_string buf "\n";

    let new_prefix = prefix ^ (if is_last then "   " else "│  ") in

    let visible_options : opt list =
      if show_hidden then cmd.options
      else List.filter (fun (o : opt) -> not o.hidden) cmd.options
    in
    let visible_args : arg list =
      if show_hidden then cmd.arguments
      else List.filter (fun (a : arg) -> not a.hidden) cmd.arguments
    in
    let visible_subs : cmd list =
      let subs = filter_ignored opts.tree_ignore cmd.subcommands in
      if show_hidden then subs
      else List.filter (fun (c : cmd) -> not c.hidden) subs
    in

    let children = ref [] in

    if visible_options <> [] then
      children := !children @ [`Group "Options"];
    List.iter (fun (o : opt) -> children := !children @ [`Opt o]) visible_options;

    if visible_args <> [] then
      children := !children @ [`Group "Arguments"];
    List.iter (fun (a : arg) -> children := !children @ [`Arg a]) visible_args;

    if visible_subs <> [] then
      children := !children @ [`Group "Subcommands"];
    List.iter (fun (c : cmd) -> children := !children @ [`Cmd c]) visible_subs;

    let rec render_children prefix items =
      match items with
      | [] -> ()
      | [last] -> render_child prefix true last
      | hd :: tl -> render_child prefix false hd; render_children prefix tl
    and render_child prefix is_last = function
      | `Group name ->
          let branch = if is_last then "└─ " else "├─ " in
          let line = prefix ^ branch ^ colorize opts "1;33" name in
          Buffer.add_string buf line;
          Buffer.add_string buf "\n"
      | `Opt o ->
          let branch = if is_last then "└─ " else "├─ " in
          let name_str = match o.short with
            | Some c -> "-" ^ String.make 1 c ^ ", --" ^ o.name
            | None -> "--" ^ o.name
          in
          let arg_str = match o.arg with Some a -> " " ^ a | None -> "" in
          let line = prefix ^ branch ^ colorize opts "32" (name_str ^ arg_str) in
          Buffer.add_string buf line;
          if o.description <> "" then
            Buffer.add_string buf ("  " ^ colorize opts "90" ("# " ^ o.description));
          Buffer.add_string buf "\n"
      | `Arg a ->
          let branch = if is_last then "└─ " else "├─ " in
          let name_str = if a.required then "<" ^ a.name ^ ">" else "[" ^ a.name ^ "]" in
          let line = prefix ^ branch ^ colorize opts "35" name_str in
          Buffer.add_string buf line;
          if a.description <> "" then
            Buffer.add_string buf ("  " ^ colorize opts "90" ("# " ^ a.description));
          Buffer.add_string buf "\n"
      | `Cmd c ->
          render_text_cmd ~max_depth ~show_hidden ~path ~style ~color opts prefix is_last buf c
    in

    render_children new_prefix !children
  end

let render_text ?(max_depth = -1) ?(show_hidden = false) ?(path = [])
    ?(style = "default") ?(color = "auto") cmd =
  let opts = {
    help_tree = true;
    tree_depth = (if max_depth >= 0 then Some max_depth else None);
    tree_ignore = [];
    tree_all = show_hidden;
    tree_output = Some "text";
    tree_style = Some style;
    tree_color = Some color;
  } in
  let buf = Buffer.create 4096 in
  let targets = if path = [] then [cmd] else find_path path [cmd] in
  let rec render_list prefix = function
    | [] -> ()
    | [last] -> render_text_cmd ~max_depth ~show_hidden ~path ~style ~color opts prefix true buf last
    | hd :: tl -> render_text_cmd ~max_depth ~show_hidden ~path ~style ~color opts prefix false buf hd; render_list prefix tl
  in
  render_list "" targets;
  Buffer.contents buf

let rec render_json_cmd ?(max_depth = -1) ?(show_hidden = false) ?(path = [])
    opts depth buf cmd =
  if max_depth >= 0 && depth > max_depth then ()
  else if not show_hidden && cmd.hidden then ()
  else begin
    Buffer.add_string buf "{\n";
    Buffer.add_string buf (Printf.sprintf "%s  \"name\": \"%s\",\n" (String.make (depth * 2) ' ') (escape_json cmd.name));
    Buffer.add_string buf (Printf.sprintf "%s  \"description\": \"%s\",\n" (String.make (depth * 2) ' ') (escape_json cmd.description));
    Buffer.add_string buf (Printf.sprintf "%s  \"hidden\": %b,\n" (String.make (depth * 2) ' ') cmd.hidden);

    let visible_options : opt list =
      if show_hidden then cmd.options
      else List.filter (fun (o : opt) -> not o.hidden) cmd.options
    in
    let visible_args : arg list =
      if show_hidden then cmd.arguments
      else List.filter (fun (a : arg) -> not a.hidden) cmd.arguments
    in
    let visible_subs : cmd list =
      let subs = filter_ignored opts.tree_ignore cmd.subcommands in
      if show_hidden then subs
      else List.filter (fun (c : cmd) -> not c.hidden) subs
    in

    Buffer.add_string buf (Printf.sprintf "%s  \"options\": [\n" (String.make (depth * 2) ' '));
    let rec render_opts (opts_list : opt list) =
      match opts_list with
      | [] -> ()
      | [last] ->
          Buffer.add_string buf (Printf.sprintf "%s    {\n" (String.make (depth * 2) ' '));
          Buffer.add_string buf (Printf.sprintf "%s      \"name\": \"%s\",\n" (String.make (depth * 2) ' ') (escape_json last.name));
          let short_str = match last.short with Some c -> String.make 1 c | None -> "" in
          Buffer.add_string buf (Printf.sprintf "%s      \"short\": \"%s\",\n" (String.make (depth * 2) ' ') (escape_json short_str));
          Buffer.add_string buf (Printf.sprintf "%s      \"description\": \"%s\",\n" (String.make (depth * 2) ' ') (escape_json last.description));
          Buffer.add_string buf (Printf.sprintf "%s      \"hidden\": %b,\n" (String.make (depth * 2) ' ') last.hidden);
          let arg_str = match last.arg with Some a -> a | None -> "" in
          Buffer.add_string buf (Printf.sprintf "%s      \"argument\": \"%s\"\n" (String.make (depth * 2) ' ') (escape_json arg_str));
          Buffer.add_string buf (Printf.sprintf "%s    }\n" (String.make (depth * 2) ' '))
      | hd :: tl ->
          Buffer.add_string buf (Printf.sprintf "%s    {\n" (String.make (depth * 2) ' '));
          Buffer.add_string buf (Printf.sprintf "%s      \"name\": \"%s\",\n" (String.make (depth * 2) ' ') (escape_json hd.name));
          let short_str = match hd.short with Some c -> String.make 1 c | None -> "" in
          Buffer.add_string buf (Printf.sprintf "%s      \"short\": \"%s\",\n" (String.make (depth * 2) ' ') (escape_json short_str));
          Buffer.add_string buf (Printf.sprintf "%s      \"description\": \"%s\",\n" (String.make (depth * 2) ' ') (escape_json hd.description));
          Buffer.add_string buf (Printf.sprintf "%s      \"hidden\": %b,\n" (String.make (depth * 2) ' ') hd.hidden);
          let arg_str = match hd.arg with Some a -> a | None -> "" in
          Buffer.add_string buf (Printf.sprintf "%s      \"argument\": \"%s\"\n" (String.make (depth * 2) ' ') (escape_json arg_str));
          Buffer.add_string buf (Printf.sprintf "%s    },\n" (String.make (depth * 2) ' '));
          render_opts tl
    in
    render_opts visible_options;
    Buffer.add_string buf (Printf.sprintf "%s  ],\n" (String.make (depth * 2) ' '));

    Buffer.add_string buf (Printf.sprintf "%s  \"arguments\": [\n" (String.make (depth * 2) ' '));
    let rec render_args (args_list : arg list) =
      match args_list with
      | [] -> ()
      | [last] ->
          Buffer.add_string buf (Printf.sprintf "%s    {\n" (String.make (depth * 2) ' '));
          Buffer.add_string buf (Printf.sprintf "%s      \"name\": \"%s\",\n" (String.make (depth * 2) ' ') (escape_json last.name));
          Buffer.add_string buf (Printf.sprintf "%s      \"description\": \"%s\",\n" (String.make (depth * 2) ' ') (escape_json last.description));
          Buffer.add_string buf (Printf.sprintf "%s      \"required\": %b,\n" (String.make (depth * 2) ' ') last.required);
          Buffer.add_string buf (Printf.sprintf "%s      \"hidden\": %b\n" (String.make (depth * 2) ' ') last.hidden);
          Buffer.add_string buf (Printf.sprintf "%s    }\n" (String.make (depth * 2) ' '))
      | hd :: tl ->
          Buffer.add_string buf (Printf.sprintf "%s    {\n" (String.make (depth * 2) ' '));
          Buffer.add_string buf (Printf.sprintf "%s      \"name\": \"%s\",\n" (String.make (depth * 2) ' ') (escape_json hd.name));
          Buffer.add_string buf (Printf.sprintf "%s      \"description\": \"%s\",\n" (String.make (depth * 2) ' ') (escape_json hd.description));
          Buffer.add_string buf (Printf.sprintf "%s      \"required\": %b,\n" (String.make (depth * 2) ' ') hd.required);
          Buffer.add_string buf (Printf.sprintf "%s      \"hidden\": %b\n" (String.make (depth * 2) ' ') hd.hidden);
          Buffer.add_string buf (Printf.sprintf "%s    },\n" (String.make (depth * 2) ' '));
          render_args tl
    in
    render_args visible_args;
    Buffer.add_string buf (Printf.sprintf "%s  ],\n" (String.make (depth * 2) ' '));

    Buffer.add_string buf (Printf.sprintf "%s  \"subcommands\": [\n" (String.make (depth * 2) ' '));
    let rec render_subs (subs_list : cmd list) =
      match subs_list with
      | [] -> ()
      | [last] -> render_json_cmd opts (depth + 1) buf last
      | hd :: tl ->
          render_json_cmd opts (depth + 1) buf hd;
          Buffer.add_string buf ",\n";
          render_subs tl
    in
    render_subs visible_subs;
    Buffer.add_string buf (Printf.sprintf "%s  ]\n" (String.make (depth * 2) ' '));
    Buffer.add_string buf (Printf.sprintf "%s}\n" (String.make (depth * 2) ' '))
  end

let render_json ?(max_depth = -1) ?(show_hidden = false) ?(path = [])
    cmd =
  let opts = {
    help_tree = true;
    tree_depth = (if max_depth >= 0 then Some max_depth else None);
    tree_ignore = [];
    tree_all = show_hidden;
    tree_output = Some "json";
    tree_style = None;
    tree_color = None;
  } in
  let buf = Buffer.create 4096 in
  let targets = if path = [] then [cmd] else find_path path [cmd] in
  let rec render_list = function
    | [] -> ()
    | [last] -> render_json_cmd ~max_depth ~show_hidden opts 0 buf last
    | hd :: tl ->
        render_json_cmd ~max_depth ~show_hidden opts 0 buf hd;
        Buffer.add_string buf ",\n"
  in
  Buffer.add_string buf "[\n";
  render_list targets;
  Buffer.add_string buf "\n]\n";
  Buffer.contents buf

let render opts cmd =
  let output = match opts.tree_output with Some o -> o | None -> "text" in
  let max_depth = match opts.tree_depth with Some d -> d | None -> -1 in
  let show_hidden = opts.tree_all in
  let style = match opts.tree_style with Some s -> s | None -> "default" in
  let color = match opts.tree_color with Some c -> c | None -> "auto" in
  if output = "json" then
    render_json ~max_depth ~show_hidden cmd
  else
    render_text ~max_depth ~show_hidden ~style ~color cmd
