local M = {}

local TREE_ALIGN_WIDTH = 28
local MIN_DOTS = 4

-- ------------------------------------------------------------------
-- Defaults
-- ------------------------------------------------------------------

function M.default_theme()
  return {
    command = { emphasis = "bold", color_hex = "#7ee7e6" },
    options = { emphasis = "normal" },
    description = { emphasis = "italic", color_hex = "#90a2af" },
  }
end

function M.default_opts()
  return {
    depth_limit = -1,
    ignore = {},
    tree_all = false,
    output = "text",
    style = "rich",
    color = "auto",
    theme = M.default_theme(),
  }
end

-- ------------------------------------------------------------------
-- Discovery options
-- ------------------------------------------------------------------

function M.discovery_options()
  return {
    { name = "help-tree", short = "", long = "--help-tree", description = "Print a recursive command map derived from framework metadata", required = false, takes_value = false, default_val = "", hidden = false },
    { name = "tree-depth", short = "-L", long = "--tree-depth", description = "Limit --help-tree recursion depth (Unix tree -L style)", required = false, takes_value = true, default_val = "", hidden = false },
    { name = "tree-ignore", short = "-I", long = "--tree-ignore", description = "Exclude subtrees/commands from --help-tree output (repeatable)", required = false, takes_value = true, default_val = "", hidden = false },
    { name = "tree-all", short = "-a", long = "--tree-all", description = "Include hidden subcommands in --help-tree output", required = false, takes_value = false, default_val = "", hidden = false },
    { name = "tree-output", short = "", long = "--tree-output", description = "Output format (text or json)", required = false, takes_value = true, default_val = "", hidden = false },
    { name = "tree-style", short = "", long = "--tree-style", description = "Tree text styling mode (rich or plain)", required = false, takes_value = true, default_val = "", hidden = false },
    { name = "tree-color", short = "", long = "--tree-color", description = "Tree color mode (auto, always, never)", required = false, takes_value = true, default_val = "", hidden = false },
  }
end

-- ------------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------------

local function isatty()
  -- Try io.stdout:isatty() if available (LuaJIT / Lua 5.3+ with luaposix)
  local stdout = io.stdout
  if type(stdout) == "userdata" and stdout.isatty then
    return stdout:isatty()
  end
  -- Fallback: use luv or luaposix if available
  local ok, mod = pcall(require, "luv")
  if ok and mod.guess_handle then
    local handle_type = mod.guess_handle(1)
    return handle_type == "tty"
  end
  ok, mod = pcall(require, "posix.unistd")
  if ok and mod.isatty then
    return mod.isatty(1) == 1
  end
  -- Last resort: assume not a tty
  return false
end

local function parse_hex(hex)
  local h = hex:gsub("^#", "")
  if #h ~= 6 then return nil end
  local r = tonumber(h:sub(1, 2), 16)
  local g = tonumber(h:sub(3, 4), 16)
  local b = tonumber(h:sub(5, 6), 16)
  if r and g and b then
    return r, g, b
  end
  return nil
end

local function should_use_color(opts)
  if opts.color == "always" then return true end
  if opts.color == "never" then return false end
  return isatty()
end

local function style_text(text, token, opts)
  if opts.style == "plain" or (token.emphasis == "normal" and not token.color_hex) then
    return text
  end

  local codes = {}
  if token.emphasis == "bold" then
    table.insert(codes, "1")
  elseif token.emphasis == "italic" then
    table.insert(codes, "3")
  elseif token.emphasis == "bold_italic" then
    table.insert(codes, "1")
    table.insert(codes, "3")
  end

  if should_use_color(opts) and token.color_hex then
    local r, g, b = parse_hex(token.color_hex)
    if r then
      table.insert(codes, string.format("38;2;%d;%d;%d", r, g, b))
    end
  end

  if #codes == 0 then
    return text
  end

  return string.format("\x1b[%sm%s\x1b[0m", table.concat(codes, ";"), text)
end

-- ------------------------------------------------------------------
-- Filtering
-- ------------------------------------------------------------------

local function should_skip_option(opt, tree_all)
  if tree_all then return false end
  if opt.hidden then return true end
  if opt.name == "help" or opt.name == "version" then return true end
  return false
end

local function should_skip_argument(arg, tree_all)
  if tree_all then return false end
  if arg.hidden then return true end
  return false
end

local function should_skip_command(cmd, opts)
  if cmd.name == "help" then return true end
  for _, ign in ipairs(opts.ignore) do
    if cmd.name == ign then return true end
  end
  if not opts.tree_all and cmd.hidden then return true end
  return false
end

-- ------------------------------------------------------------------
-- Signature
-- ------------------------------------------------------------------

local function command_signature(cmd, tree_all)
  local parts = {}
  for _, a in ipairs(cmd.arguments or {}) do
    if not should_skip_argument(a, tree_all) then
      if a.required then
        table.insert(parts, string.format(" <%s>", a.name))
      else
        table.insert(parts, string.format(" [%s]", a.name))
      end
    end
  end
  local has_flags = false
  for _, o in ipairs(cmd.options or {}) do
    if not should_skip_option(o, tree_all) then
      has_flags = true
      break
    end
  end
  if has_flags then
    table.insert(parts, " [flags]")
  end
  return table.concat(parts)
end

-- ------------------------------------------------------------------
-- Text rendering
-- ------------------------------------------------------------------

local function render_text_lines(cmd, prefix, depth, opts)
  local visible = {}
  for _, sub in ipairs(cmd.subcommands or {}) do
    if not should_skip_command(sub, opts) then
      table.insert(visible, sub)
    end
  end
  if #visible == 0 then
    return {}
  end

  local at_limit = opts.depth_limit >= 0 and depth >= opts.depth_limit
  local lines = {}

  for i, sub in ipairs(visible) do
    local is_last = (i == #visible)
    local branch = is_last and "\226\148\148\226\148\128\226\148\128 " or "\226\148\156\226\148\128\226\148\128 "
    -- UTF-8 for "└── " and "├── "

    local sig = command_signature(sub, opts.tree_all)
    local signature = sub.name .. sig

    local styled_name = style_text(sub.name, opts.theme.command, opts)
    local styled_suffix = style_text(sig, opts.theme.options, opts)

    local line = prefix .. branch .. styled_name .. styled_suffix

    if sub.description and sub.description ~= "" then
      local dots_len = math.max(MIN_DOTS, TREE_ALIGN_WIDTH - #signature)
      line = line .. " " .. string.rep(".", dots_len) .. " " .. style_text(sub.description, opts.theme.description, opts)
    end

    table.insert(lines, line)

    if not at_limit then
      local ext = is_last and "    " or "\226\148\130   "
      -- "│   "
      local child_lines = render_text_lines(sub, prefix .. ext, depth + 1, opts)
      for _, cl in ipairs(child_lines) do
        table.insert(lines, cl)
      end
    end
  end

  return lines
end

function M.render_text(cmd, opts)
  local parts = {}

  table.insert(parts, style_text(cmd.name, opts.theme.command, opts))

  for _, opt in ipairs(cmd.options or {}) do
    if not should_skip_option(opt, opts.tree_all) then
      local meta
      if opt.short ~= "" and opt.long ~= "" then
        meta = string.format("%s, %s", opt.short, opt.long)
      elseif opt.long ~= "" then
        meta = opt.long
      elseif opt.short ~= "" then
        meta = opt.short
      else
        meta = opt.name
      end
      table.insert(parts, string.format("  %s \226\128\166 %s", style_text(meta, opts.theme.options, opts), style_text(opt.description, opts.theme.description, opts)))
    end
  end

  if cmd.subcommands and #cmd.subcommands > 0 then
    table.insert(parts, "")
    local lines = render_text_lines(cmd, "", 0, opts)
    for _, line in ipairs(lines) do
      table.insert(parts, line)
    end
  end

  return table.concat(parts, "\n")
end

-- ------------------------------------------------------------------
-- JSON rendering
-- ------------------------------------------------------------------

local function json_escape(s)
  local result = {}
  for i = 1, #s do
    local c = s:sub(i, i)
    if c == '"' then
      table.insert(result, '\\"')
    elseif c == '\\' then
      table.insert(result, '\\\\')
    elseif c == '\b' then
      table.insert(result, '\\b')
    elseif c == '\f' then
      table.insert(result, '\\f')
    elseif c == '\n' then
      table.insert(result, '\\n')
    elseif c == '\r' then
      table.insert(result, '\\r')
    elseif c == '\t' then
      table.insert(result, '\\t')
    else
      table.insert(result, c)
    end
  end
  return table.concat(result)
end

local function option_to_json(opt)
  local parts = {}
  table.insert(parts, string.format('{"type":"option","name":"%s"', json_escape(opt.name)))
  if opt.description and opt.description ~= "" then
    table.insert(parts, string.format('"description":"%s"', json_escape(opt.description)))
  end
  if opt.short and opt.short ~= "" then
    table.insert(parts, string.format('"short":"%s"', json_escape(opt.short)))
  end
  if opt.long and opt.long ~= "" then
    table.insert(parts, string.format('"long":"%s"', json_escape(opt.long)))
  end
  if opt.default_val and opt.default_val ~= "" then
    table.insert(parts, string.format('"default":"%s"', json_escape(opt.default_val)))
  end
  table.insert(parts, string.format('"required":%s', opt.required and "true" or "false"))
  table.insert(parts, string.format('"takes_value":%s', opt.takes_value and "true" or "false"))
  return table.concat(parts, ",") .. "}"
end

local function argument_to_json(arg)
  local parts = {}
  table.insert(parts, string.format('{"type":"argument","name":"%s"', json_escape(arg.name)))
  if arg.description and arg.description ~= "" then
    table.insert(parts, string.format('"description":"%s"', json_escape(arg.description)))
  end
  table.insert(parts, string.format('"required":%s', arg.required and "true" or "false"))
  return table.concat(parts, ",") .. "}"
end

local function cmd_to_json(cmd, opts, depth)
  local parts = {}
  table.insert(parts, string.format('{"type":"command","name":"%s"', json_escape(cmd.name)))
  if cmd.description and cmd.description ~= "" then
    table.insert(parts, string.format('"description":"%s"', json_escape(cmd.description)))
  end

  -- options
  local opt_count = 0
  for _, o in ipairs(cmd.options or {}) do
    if not should_skip_option(o, opts.tree_all) then opt_count = opt_count + 1 end
  end
  if opt_count > 0 then
    local opts_parts = {}
    for _, o in ipairs(cmd.options or {}) do
      if not should_skip_option(o, opts.tree_all) then
        table.insert(opts_parts, option_to_json(o))
      end
    end
    table.insert(parts, string.format('"options":[%s]', table.concat(opts_parts, ",")))
  end

  -- arguments
  local arg_count = 0
  for _, a in ipairs(cmd.arguments or {}) do
    if not should_skip_argument(a, opts.tree_all) then arg_count = arg_count + 1 end
  end
  if arg_count > 0 then
    local args_parts = {}
    for _, a in ipairs(cmd.arguments or {}) do
      if not should_skip_argument(a, opts.tree_all) then
        table.insert(args_parts, argument_to_json(a))
      end
    end
    table.insert(parts, string.format('"arguments":[%s]', table.concat(args_parts, ",")))
  end

  -- subcommands
  local can_recurse = opts.depth_limit < 0 or depth < opts.depth_limit
  if can_recurse then
    local sub_count = 0
    for _, s in ipairs(cmd.subcommands or {}) do
      if not should_skip_command(s, opts) then sub_count = sub_count + 1 end
    end
    if sub_count > 0 then
      local subs_parts = {}
      for _, s in ipairs(cmd.subcommands or {}) do
        if not should_skip_command(s, opts) then
          table.insert(subs_parts, cmd_to_json(s, opts, depth + 1))
        end
      end
      table.insert(parts, string.format('"subcommands":[%s]', table.concat(subs_parts, ",")))
    end
  end

  return table.concat(parts, ",") .. "}"
end

function M.render_json(cmd, opts)
  return cmd_to_json(cmd, opts, 0)
end

-- ------------------------------------------------------------------
-- Path targeting
-- ------------------------------------------------------------------

function M.find_by_path(root, path)
  local result = root
  for _, token in ipairs(path) do
    local found = false
    for _, sub in ipairs(result.subcommands or {}) do
      if sub.name == token then
        result = sub
        found = true
        break
      end
    end
    if not found then break end
  end
  return result
end

-- ------------------------------------------------------------------
-- Parsing
-- ------------------------------------------------------------------

function M.parse_invocation(raw_args)
  local help_tree = false
  local depth_limit = -1
  local ignore = {}
  local tree_all = false
  local output = "text"
  local style = "rich"
  local color = "auto"
  local path = {}

  local args = {}
  for i = 1, #raw_args do
    table.insert(args, raw_args[i])
  end

  local i = 1
  while i <= #args do
    local a = args[i]
    if a == "--help-tree" then
      help_tree = true
    elseif (a == "--tree-depth" or a == "-L") and i + 1 <= #args then
      i = i + 1
      local val = tonumber(args[i])
      if val and val >= 0 then
        depth_limit = val
      end
    elseif (a == "--tree-ignore" or a == "-I") and i + 1 <= #args then
      i = i + 1
      table.insert(ignore, args[i])
    elseif a == "--tree-all" or a == "-a" then
      tree_all = true
    elseif a == "--tree-output" and i + 1 <= #args then
      i = i + 1
      if args[i] == "json" then output = "json" else output = "text" end
    elseif a == "--tree-style" and i + 1 <= #args then
      i = i + 1
      if args[i] == "plain" then style = "plain" else style = "rich" end
    elseif a == "--tree-color" and i + 1 <= #args then
      i = i + 1
      if args[i] == "always" then color = "always"
      elseif args[i] == "never" then color = "never"
      else color = "auto" end
    elseif a:sub(1, 1) ~= "-" then
      table.insert(path, a)
    end
    i = i + 1
  end

  if not help_tree then
    return nil
  end

  local opts = M.default_opts()
  opts.depth_limit = depth_limit
  opts.ignore = ignore
  opts.tree_all = tree_all
  opts.output = output
  opts.style = style
  opts.color = color

  return {
    opts = opts,
    path = path,
  }
end

-- ------------------------------------------------------------------
-- Config loading
-- ------------------------------------------------------------------

local function json_skip_ws(s, pos)
  while pos <= #s and s:sub(pos, pos):match("[%s]") do
    pos = pos + 1
  end
  return pos
end

local function json_parse_string(s, pos)
  pos = json_skip_ws(s, pos)
  if pos > #s or s:sub(pos, pos) ~= '"' then return nil, pos end
  pos = pos + 1
  local start = pos
  while pos <= #s and s:sub(pos, pos) ~= '"' do
    pos = pos + 1
  end
  local val = s:sub(start, pos - 1)
  if pos <= #s then pos = pos + 1 end
  return val, pos
end

local function json_expect_char(s, pos, c)
  pos = json_skip_ws(s, pos)
  if pos <= #s and s:sub(pos, pos) == c then
    return pos + 1
  end
  return nil
end

local function parse_token_theme(s, pos)
  pos = json_expect_char(s, pos, '{')
  if not pos then return nil, pos end
  local token = { emphasis = "normal" }
  while true do
    pos = json_skip_ws(s, pos)
    if pos <= #s and s:sub(pos, pos) == '}' then
      pos = pos + 1
      break
    end
    local key
    key, pos = json_parse_string(s, pos)
    if not key then return nil, pos end
    pos = json_expect_char(s, pos, ':')
    if not pos then return nil, pos end
    local val
    val, pos = json_parse_string(s, pos)
    if not val then return nil, pos end
    if key == "emphasis" then
      token.emphasis = val
    elseif key == "color_hex" then
      token.color_hex = val
    end
    pos = json_skip_ws(s, pos)
    if pos <= #s and s:sub(pos, pos) == ',' then
      pos = pos + 1
    elseif pos <= #s and s:sub(pos, pos) == '}' then
      pos = pos + 1
      break
    else
      return nil, pos
    end
  end
  return token, pos
end

local function parse_theme(s, pos)
  pos = json_expect_char(s, pos, '{')
  if not pos then return nil, pos end
  local theme = {
    command = { emphasis = "bold", color_hex = "#7ee7e6" },
    options = { emphasis = "normal" },
    description = { emphasis = "italic", color_hex = "#90a2af" },
  }
  while true do
    pos = json_skip_ws(s, pos)
    if pos <= #s and s:sub(pos, pos) == '}' then
      pos = pos + 1
      break
    end
    local key
    key, pos = json_parse_string(s, pos)
    if not key then return nil, pos end
    pos = json_expect_char(s, pos, ':')
    if not pos then return nil, pos end
    local token
    token, pos = parse_token_theme(s, pos)
    if not token then return nil, pos end
    if key == "command" then theme.command = token
    elseif key == "options" then theme.options = token
    elseif key == "description" then theme.description = token
    end
    pos = json_skip_ws(s, pos)
    if pos <= #s and s:sub(pos, pos) == ',' then
      pos = pos + 1
    elseif pos <= #s and s:sub(pos, pos) == '}' then
      pos = pos + 1
      break
    else
      return nil, pos
    end
  end
  return theme, pos
end

function M.load_config(path)
  local f, err = io.open(path, "r")
  if not f then return nil end
  local data = f:read("*all")
  f:close()
  if not data then return nil end

  local pos = 1
  pos = json_expect_char(data, pos, '{')
  if not pos then return nil end
  local config = { theme = nil }
  while true do
    pos = json_skip_ws(data, pos)
    if pos <= #data and data:sub(pos, pos) == '}' then
      pos = pos + 1
      break
    end
    local key
    key, pos = json_parse_string(data, pos)
    if not key then return nil end
    pos = json_expect_char(data, pos, ':')
    if not pos then return nil end
    if key == "theme" then
      local theme
      theme, pos = parse_theme(data, pos)
      if not theme then return nil end
      config.theme = theme
    else
      return nil
    end
    pos = json_skip_ws(data, pos)
    if pos <= #data and data:sub(pos, pos) == ',' then
      pos = pos + 1
    elseif pos <= #data and data:sub(pos, pos) == '}' then
      pos = pos + 1
      break
    else
      return nil
    end
  end
  return config
end

function M.apply_config(opts, config)
  if config and config.theme then
    opts.theme = config.theme
  end
end

-- ------------------------------------------------------------------
-- Convenience
-- ------------------------------------------------------------------

function M.run(root, raw_args)
  local inv = M.parse_invocation(raw_args)
  if not inv then
    return false
  end

  local selected = M.find_by_path(root, inv.path)
  if inv.opts.output == "json" then
    print(M.render_json(selected, inv.opts))
  else
    print(M.render_text(selected, inv.opts))
    print()
    print(string.format("Use `%s <COMMAND> --help` for full details on arguments and flags.", root.name))
  end
  return true
end

return M
