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

type theme_token = {
  emphasis : string;
  color_hex : string option;
}

type theme = {
  command : theme_token;
  options : theme_token;
  description : theme_token;
}

let tree_align_width = 28
let min_dots = 4

let default_theme () = {
  command = { emphasis = "bold"; color_hex = Some "#7ee7e6" };
  options = { emphasis = "normal"; color_hex = None };
  description = { emphasis = "italic"; color_hex = Some "#90a2af" };
}

let parse_hex_rgb hex =
  let h = if String.length hex > 0 && hex.[0] = '#' then String.sub hex 1 (String.length hex - 1) else hex in
  if String.length h <> 6 then None
  else try
    let r = int_of_string ("0x" ^ String.sub h 0 2) in
    let g = int_of_string ("0x" ^ String.sub h 2 2) in
    let b = int_of_string ("0x" ^ String.sub h 4 2) in
    Some (r, g, b)
  with Failure _ -> None

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

let use_rich_style opts =
  match opts.tree_style with
  | Some "plain" -> false
  | _ -> true

let style_text text token opts =
  if not (use_rich_style opts) ||
     (token.emphasis = "normal" && token.color_hex = None) then
    text
  else
    let codes = ref [] in
    (match token.emphasis with
     | "bold" -> codes := "1" :: !codes
     | "italic" -> codes := "3" :: !codes
     | "bold_italic" -> codes := "1" :: "3" :: !codes
     | _ -> ());
    (if use_color opts then
       match token.color_hex with
       | Some hex ->
           (match parse_hex_rgb hex with
            | Some (r, g, b) -> codes := Printf.sprintf "38;2;%d;%d;%d" r g b :: !codes
            | None -> ())
       | None -> ());
    if !codes = [] then text
    else "\027[" ^ String.concat ";" (List.rev !codes) ^ "m" ^ text ^ "\027[0m"

let should_skip_option (opt : opt) tree_all =
  if tree_all then false
  else if opt.hidden then true
  else if opt.name = "help" || opt.name = "version" then true
  else false

let should_skip_argument (arg : arg) tree_all =
  if tree_all then false
  else if arg.hidden then true
  else false

let should_skip_command (cmd : cmd) opts =
  if cmd.name = "help" then true
  else if List.mem cmd.name opts.tree_ignore then true
  else if not opts.tree_all && cmd.hidden then true
  else false

let command_signature (cmd : cmd) tree_all =
  let suffix = ref "" in
  List.iter (fun (arg : arg) ->
    if not (should_skip_argument arg tree_all) then
      suffix := !suffix ^ (if arg.required then " <" ^ arg.name ^ ">" else " [" ^ arg.name ^ "]")
  ) cmd.arguments;
  let has_flags = List.exists (fun (opt : opt) -> not (should_skip_option opt tree_all)) cmd.options in
  if has_flags then suffix := !suffix ^ " [flags]";
  (cmd.name, !suffix)

let rec render_text_lines buf (cmd : cmd) prefix depth opts =
  let items = List.filter (fun (sub : cmd) -> not (should_skip_command sub opts)) cmd.subcommands in
  if items = [] then ()
  else
    let at_limit = match opts.tree_depth with Some dl -> depth >= dl | None -> false in
    let rec render_item idx = function
      | [] -> ()
      | sub :: rest ->
          let is_last = idx = List.length items - 1 in
          let branch = if is_last then "└── " else "├── " in
          let name, suffix = command_signature sub opts.tree_all in
          let signature = name ^ suffix in
          let about = sub.description in
          let t = default_theme () in
          let name_styled = style_text name t.command opts in
          let suffix_styled = style_text suffix t.options opts in
          Buffer.add_string buf (prefix ^ branch ^ name_styled ^ suffix_styled);
          if about <> "" then begin
            let sig_len = String.length signature in
            let dots_len = max min_dots (tree_align_width - sig_len) in
            Buffer.add_string buf (" " ^ String.make dots_len '.' ^ " ");
            Buffer.add_string buf (style_text about t.description opts)
          end;
          Buffer.add_string buf "\n";
          if not at_limit then begin
            let extension = if is_last then "    " else "│   " in
            render_text_lines buf sub (prefix ^ extension) (depth + 1) opts
          end;
          render_item (idx + 1) rest
    in
    render_item 0 items

let render_text buf (cmd : cmd) opts =
  let t = default_theme () in
  Buffer.add_string buf (style_text cmd.name t.command opts);
  Buffer.add_string buf "\n";
  List.iter (fun (opt : opt) ->
    if not (should_skip_option opt opts.tree_all) then begin
      let meta =
        if opt.short <> "" && opt.long <> "" then opt.short ^ ", " ^ opt.long
        else if opt.long <> "" then opt.long
        else if opt.short <> "" then opt.short
        else opt.name
      in
      Buffer.add_string buf ("  " ^ style_text meta t.options opts ^ " … " ^ style_text opt.description t.description opts);
      Buffer.add_string buf "\n"
    end
  ) cmd.options;
  if cmd.subcommands <> [] then begin
    Buffer.add_string buf "\n";
    render_text_lines buf cmd "" 0 opts
  end

let escape_json s =
  let buf = Buffer.create (String.length s * 2) in
  String.iter (function
    | '"' -> Buffer.add_string buf "\\\""
    | '\\' -> Buffer.add_string buf "\\\\"
    | '\b' -> Buffer.add_string buf "\\b"
    | '\n' -> Buffer.add_string buf "\\n"
    | '\r' -> Buffer.add_string buf "\\r"
    | '\t' -> Buffer.add_string buf "\\t"
    | c -> Buffer.add_char buf c
  ) s;
  Buffer.contents buf

let option_to_json buf (opt : opt) =
  Buffer.add_string buf "{\"type\":\"option\",\"name\":\"";
  Buffer.add_string buf (escape_json opt.name);
  Buffer.add_string buf "\"";
  if opt.description <> "" then begin
    Buffer.add_string buf ",\"description\":\"";
    Buffer.add_string buf (escape_json opt.description);
    Buffer.add_string buf "\""
  end;
  if opt.short <> "" then begin
    Buffer.add_string buf ",\"short\":\"";
    Buffer.add_string buf (escape_json opt.short);
    Buffer.add_string buf "\""
  end;
  if opt.long <> "" then begin
    Buffer.add_string buf ",\"long\":\"";
    Buffer.add_string buf (escape_json opt.long);
    Buffer.add_string buf "\""
  end;
  if opt.default_val <> "" then begin
    Buffer.add_string buf ",\"default\":\"";
    Buffer.add_string buf (escape_json opt.default_val);
    Buffer.add_string buf "\""
  end;
  Buffer.add_string buf ",\"required\":";
  Buffer.add_string buf (if opt.required then "true" else "false");
  Buffer.add_string buf ",\"takes_value\":";
  Buffer.add_string buf (if opt.takes_value then "true" else "false");
  Buffer.add_string buf "}"

let argument_to_json buf (arg : arg) =
  Buffer.add_string buf "{\"type\":\"argument\",\"name\":\"";
  Buffer.add_string buf (escape_json arg.name);
  Buffer.add_string buf "\"";
  if arg.description <> "" then begin
    Buffer.add_string buf ",\"description\":\"";
    Buffer.add_string buf (escape_json arg.description);
    Buffer.add_string buf "\""
  end;
  Buffer.add_string buf ",\"required\":";
  Buffer.add_string buf (if arg.required then "true" else "false");
  Buffer.add_string buf "}"

let rec cmd_to_json buf (cmd : cmd) opts depth =
  Buffer.add_string buf "{\"type\":\"command\",\"name\":\"";
  Buffer.add_string buf (escape_json cmd.name);
  Buffer.add_string buf "\"";
  if cmd.description <> "" then begin
    Buffer.add_string buf ",\"description\":\"";
    Buffer.add_string buf (escape_json cmd.description);
    Buffer.add_string buf "\""
  end;
  let opts_arr = List.filter (fun opt -> not (should_skip_option opt opts.tree_all)) cmd.options in
  if opts_arr <> [] then begin
    Buffer.add_string buf ",\"options\":[";
    let rec render_opts first = function
      | [] -> ()
      | hd :: tl ->
          if not first then Buffer.add_string buf ",";
          option_to_json buf hd;
          render_opts false tl
    in
    render_opts true opts_arr;
    Buffer.add_string buf "]"
  end;
  let args_arr = List.filter (fun arg -> not (should_skip_argument arg opts.tree_all)) cmd.arguments in
  if args_arr <> [] then begin
    Buffer.add_string buf ",\"arguments\":[";
    let rec render_args first = function
      | [] -> ()
      | hd :: tl ->
          if not first then Buffer.add_string buf ",";
          argument_to_json buf hd;
          render_args false tl
    in
    render_args true args_arr;
    Buffer.add_string buf "]"
  end;
  let can_recurse = match opts.tree_depth with Some dl -> depth < dl | None -> true in
  if can_recurse then begin
    let subs = List.filter (fun sub -> not (should_skip_command sub opts)) cmd.subcommands in
    if subs <> [] then begin
      Buffer.add_string buf ",\"subcommands\":[";
      let rec render_subs first = function
        | [] -> ()
        | hd :: tl ->
            if not first then Buffer.add_string buf ",";
            cmd_to_json buf hd opts (depth + 1);
            render_subs false tl
      in
      render_subs true subs;
      Buffer.add_string buf "]"
    end
  end;
  Buffer.add_string buf "}"

let rec find_by_path cmd path =
  match path with
  | [] -> cmd
  | token :: rest ->
      let found = List.find_opt (fun sub -> sub.name = token) cmd.subcommands in
      match found with
      | Some sub -> find_by_path sub rest
      | None -> cmd

let render opts cmd =
  let buf = Buffer.create 4096 in
  let selected = find_by_path cmd opts.path in
  let output = match opts.tree_output with Some o -> o | None -> "text" in
  if output = "json" then begin
    cmd_to_json buf selected opts 0;
    Buffer.add_string buf "\n"
  end else begin
    render_text buf selected opts;
    Buffer.add_string buf "\n\nUse `";
    Buffer.add_string buf cmd.name;
    Buffer.add_string buf " <COMMAND> --help` for full details on arguments and flags.\n"
  end;
  Buffer.contents buf

let rec parse_args args acc =
  match args with
  | [] -> acc
  | "--help-tree" :: rest -> parse_args rest { acc with help_tree = true }
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
  | arg :: rest when String.length arg > 0 && arg.[0] <> '-' ->
      if not acc.help_tree then
        parse_args rest { acc with path = arg :: acc.path }
      else
        parse_args rest acc
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
    path = [];
  } in
  let opts = parse_args (List.tl (Array.to_list Sys.argv)) defaults in
  { opts with path = List.rev opts.path }

let should_render_tree opts = opts.help_tree
