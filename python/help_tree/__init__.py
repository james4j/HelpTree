"""CLI help-tree discovery (`--help-tree`) built from argparse reflection."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from typing import Any

TREE_ALIGN_WIDTH = 28
MIN_DOTS = 4


class TextEmphasis:
    Normal = "normal"
    Bold = "bold"
    Italic = "italic"
    BoldItalic = "bold_italic"


@dataclass
class TextTokenTheme:
    emphasis: str = TextEmphasis.Normal
    color_hex: str | None = None

    @classmethod
    def normal(cls) -> TextTokenTheme:
        return cls()


@dataclass
class HelpTreeTheme:
    command: TextTokenTheme = field(
        default_factory=lambda: TextTokenTheme(
            emphasis=TextEmphasis.Bold, color_hex="#7ee7e6"
        )
    )
    options: TextTokenTheme = field(default_factory=TextTokenTheme.normal)
    description: TextTokenTheme = field(
        default_factory=lambda: TextTokenTheme(
            emphasis=TextEmphasis.Italic, color_hex="#90a2af"
        )
    )


class HelpTreeOutputFormat:
    Text = "text"
    Json = "json"


class HelpTreeStyle:
    Plain = "plain"
    Rich = "rich"


class HelpTreeColor:
    Auto = "auto"
    Always = "always"
    Never = "never"


@dataclass
class HelpTreeOpts:
    depth_limit: int | None = None
    ignore: list[str] = field(default_factory=list)
    tree_all: bool = False
    output: str = HelpTreeOutputFormat.Text
    style: str = HelpTreeStyle.Rich
    color: str = HelpTreeColor.Auto
    theme: HelpTreeTheme = field(default_factory=HelpTreeTheme)


@dataclass
class HelpTreeInvocation:
    opts: HelpTreeOpts
    path: list[str]


@dataclass
class HelpTreeConfigFile:
    """Config file schema for help-tree (JSON)."""
    theme: HelpTreeTheme | None = None


def load_config(path: str) -> HelpTreeConfigFile:
    """Load a help-tree config file from the given path.

    Supports `.json` files. Returns a HelpTreeConfigFile on success.
    """
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    theme_data = data.get("theme")
    theme = None
    if theme_data:
        theme = HelpTreeTheme(
            command=_token_from_json(theme_data.get("command", {})),
            options=_token_from_json(theme_data.get("options", {})),
            description=_token_from_json(theme_data.get("description", {})),
        )
    return HelpTreeConfigFile(theme=theme)


def _token_from_json(data: dict[str, Any]) -> TextTokenTheme:
    return TextTokenTheme(
        emphasis=data.get("emphasis", TextEmphasis.Normal),
        color_hex=data.get("color_hex"),
    )


def apply_config(opts: HelpTreeOpts, config: HelpTreeConfigFile) -> None:
    """Merge a loaded config file into existing opts, overriding the theme if present."""
    if config.theme is not None:
        opts.theme = config.theme


def _should_use_color(opts: HelpTreeOpts) -> bool:
    if opts.color == HelpTreeColor.Always:
        return True
    if opts.color == HelpTreeColor.Never:
        return False
    return sys.stdout.isatty()


def _parse_hex_rgb(color_hex: str) -> tuple[int, int, int] | None:
    hex_str = color_hex.lstrip("#")
    if len(hex_str) != 6:
        return None
    try:
        r = int(hex_str[0:2], 16)
        g = int(hex_str[2:4], 16)
        b = int(hex_str[4:6], 16)
        return r, g, b
    except ValueError:
        return None


def _style_text(text: str, token: TextTokenTheme, opts: HelpTreeOpts) -> str:
    if opts.style == HelpTreeStyle.Plain or (
        token.emphasis == TextEmphasis.Normal and token.color_hex is None
    ):
        return text

    codes: list[str] = []
    if token.emphasis == TextEmphasis.Bold:
        codes.append("1")
    elif token.emphasis == TextEmphasis.Italic:
        codes.append("3")
    elif token.emphasis == TextEmphasis.BoldItalic:
        codes.extend(["1", "3"])

    if _should_use_color(opts):
        if token.color_hex:
            rgb = _parse_hex_rgb(token.color_hex)
            if rgb:
                codes.append(f"38;2;{rgb[0]};{rgb[1]};{rgb[2]}")

    if not codes:
        return text
    return f"\x1b[{';'.join(codes)}m{text}\x1b[0m"


def _should_skip_action(action: argparse.Action, tree_all: bool) -> bool:
    if tree_all:
        return False
    if isinstance(action, (argparse._HelpAction, argparse._VersionAction, argparse._SubParsersAction)):
        return True
    if hasattr(action, "help") and action.help == argparse.SUPPRESS:
        return True
    return False


def _is_subparser_hidden(parent: argparse.ArgumentParser, name: str) -> bool:
    for action in parent._actions:
        if isinstance(action, argparse._SubParsersAction):
            for choice_action in action._choices_actions:
                if choice_action.dest == name:
                    return choice_action.help == argparse.SUPPRESS
    return False


def _should_skip_parser(name: str, parent: argparse.ArgumentParser, ignore: set[str], tree_all: bool) -> bool:
    if name == "help":
        return True
    if name in ignore:
        return True
    if not tree_all and _is_subparser_hidden(parent, name):
        return True
    return False


def _is_help_tree_flag(action: argparse.Action) -> bool:
    return action.dest in {
        "help_tree",
        "tree_depth",
        "tree_ignore",
        "tree_all",
        "tree_output",
        "tree_style",
        "tree_color",
    }


def _command_inline_parts(parser: argparse.ArgumentParser, tree_all: bool) -> tuple[str, str]:
    suffix = ""
    for action in parser._actions:
        if _should_skip_action(action, tree_all):
            continue
        if isinstance(action, argparse._SubParsersAction):
            continue
        if not action.option_strings:
            label = action.dest.upper()
            if action.required:
                suffix += f" <{label}>"
            else:
                suffix += f" [{label}]"

    has_flags = any(
        action.option_strings and not _should_skip_action(action, tree_all)
        for action in parser._actions
    )
    if has_flags:
        suffix += " [flags]"

    return parser.prog.split()[-1], suffix


def _get_subparsers(parser: argparse.ArgumentParser) -> dict[str, argparse.ArgumentParser] | None:
    """Extract subparser mapping from an argparse parser."""
    for action in parser._actions:
        if isinstance(action, argparse._SubParsersAction):
            return dict(action.choices)
    return None


def _get_subparser_help(parser: argparse.ArgumentParser, name: str) -> str:
    """Get the help text for a subparser as registered on its parent."""
    for action in parser._actions:
        if isinstance(action, argparse._SubParsersAction):
            for choice_action in action._choices_actions:
                if choice_action.dest == name:
                    if choice_action.help == argparse.SUPPRESS:
                        return ""
                    return choice_action.help or ""
    return ""


def _action_to_json(action: argparse.Action, tree_all: bool) -> dict[str, Any] | None:
    if _should_skip_action(action, tree_all):
        return None

    out: dict[str, Any] = {}
    if action.option_strings:
        out["type"] = "option"
        out["name"] = action.dest
        if action.help and action.help != argparse.SUPPRESS:
            out["description"] = action.help
        short = [s for s in action.option_strings if s.startswith("-") and not s.startswith("--")]
        long = [s for s in action.option_strings if s.startswith("--")]
        if short:
            out["short"] = short[0]
        if long:
            out["long"] = long[0]
        if action.default is not None and action.default != argparse.SUPPRESS:
            out["default"] = str(action.default)
        out["required"] = bool(action.required)
        out["takes_value"] = action.nargs != 0
    else:
        out["type"] = "argument"
        out["name"] = action.dest.upper()
        if action.help and action.help != argparse.SUPPRESS:
            out["description"] = action.help
        out["required"] = bool(action.required)

    return out


def _parser_to_json(
    parser: argparse.ArgumentParser,
    ignore: set[str],
    tree_all: bool,
    depth_limit: int | None,
    depth: int,
    omit_help_tree_flags: bool,
) -> dict[str, Any]:
    out: dict[str, Any] = {
        "type": "command",
        "name": parser.prog.split()[-1],
    }
    if parser.description:
        out["description"] = parser.description

    options = []
    positionals = []
    for action in parser._actions:
        if omit_help_tree_flags and _is_help_tree_flag(action):
            continue
        payload = _action_to_json(action, tree_all)
        if payload is None:
            continue
        if payload["type"] == "option":
            options.append(payload)
        else:
            positionals.append(payload)

    if options:
        out["options"] = options
    if positionals:
        out["arguments"] = positionals

    children = []
    can_recurse = depth_limit is None or depth < depth_limit
    if can_recurse:
        subs = _get_subparsers(parser)
        if subs:
            for name, sub in subs.items():
                if _should_skip_parser(name, parser, ignore, tree_all):
                    continue
                child = _parser_to_json(sub, ignore, tree_all, depth_limit, depth + 1, omit_help_tree_flags)
                sub_help = _get_subparser_help(parser, name)
                if sub_help:
                    child["description"] = sub_help
                children.append(child)
    if children:
        out["subcommands"] = children

    return out


def _write_parser_tree_lines(
    parser: argparse.ArgumentParser,
    prefix: str,
    depth: int,
    ignore: set[str],
    tree_all: bool,
    depth_limit: int | None,
    opts: HelpTreeOpts,
    out: list[str],
) -> None:
    subs = _get_subparsers(parser)
    if not subs:
        return

    items = [
        (name, sub)
        for name, sub in subs.items()
        if not _should_skip_parser(name, parser, ignore, tree_all)
    ]

    if not items:
        return

    at_limit = depth_limit is not None and depth >= depth_limit

    for idx, (name, sub) in enumerate(items):
        is_last = idx + 1 == len(items)
        branch = "└── " if is_last else "├── "
        command_name, suffix = _command_inline_parts(sub, tree_all)
        signature = f"{command_name}{suffix}"
        about = _get_subparser_help(parser, name) or sub.description or ""
        signature_styled = (
            _style_text(command_name, opts.theme.command, opts)
            + _style_text(suffix, opts.theme.options, opts)
        )
        if about:
            dots = "." * max(MIN_DOTS, TREE_ALIGN_WIDTH - len(signature))
            decorated = f"{signature_styled} {dots} {_style_text(about, opts.theme.description, opts)}"
        else:
            decorated = signature_styled

        out.append(f"{prefix}{branch}{decorated}")

        if at_limit:
            continue

        extension = "    " if is_last else "│   "
        _write_parser_tree_lines(
            sub, prefix + extension, depth + 1, ignore, tree_all, depth_limit, opts, out
        )


def _parser_to_text(
    parser: argparse.ArgumentParser,
    ignore: set[str],
    tree_all: bool,
    depth_limit: int | None,
    opts: HelpTreeOpts,
) -> str:
    out: list[str] = []
    out.append(_style_text(parser.prog.split()[-1], opts.theme.command, opts))

    for action in parser._actions:
        if _should_skip_action(action, tree_all):
            continue
        if not action.option_strings:
            continue

        long = next((s for s in action.option_strings if s.startswith("--")), action.dest)
        short = next((s for s in action.option_strings if not s.startswith("--")), "")
        meta = f"{short}, {long}" if short else long
        help_text = action.help if action.help and action.help != argparse.SUPPRESS else ""
        out.append(
            f"  {_style_text(meta, opts.theme.options, opts)} … {_style_text(help_text, opts.theme.description, opts)}"
        )

    out.append("")
    _write_parser_tree_lines(parser, "", 0, ignore, tree_all, depth_limit, opts, out)
    return "\n".join(out).rstrip()


def run_for_parser(
    parser: argparse.ArgumentParser,
    opts: HelpTreeOpts | None = None,
    requested_path: list[str] | None = None,
) -> None:
    """Render help-tree for an argparse parser.

    Args:
        parser: The argparse parser to introspect.
        opts: Options controlling output format, style, and filtering.
        requested_path: Subcommand path to root the tree at (e.g., ["project"]).
    """
    if opts is None:
        opts = HelpTreeOpts()
    if requested_path is None:
        requested_path = []

    selected = _select_parser_by_path(parser, requested_path)
    ignore = set(opts.ignore)

    if opts.output == HelpTreeOutputFormat.Json:
        omit_flags = bool(requested_path)
        value = _parser_to_json(selected, ignore, opts.tree_all, opts.depth_limit, 0, omit_flags)
        print(json.dumps(value, indent=2))
    else:
        print(_parser_to_text(selected, ignore, opts.tree_all, opts.depth_limit, opts))
        print()
        print(f"Use `{parser.prog.split()[0]} <COMMAND> --help` for full details on arguments and flags.")


def _select_parser_by_path(
    parser: argparse.ArgumentParser, tokens: list[str]
) -> argparse.ArgumentParser:
    current = parser
    for token in tokens:
        subs = _get_subparsers(current)
        if subs and token in subs:
            current = subs[token]
        else:
            break
    return current


def parse_help_tree_invocation(argv: list[str]) -> HelpTreeInvocation | None:
    """Scan argv for `--help-tree` and related flags.

    Returns None if `--help-tree` is not present.
    """
    help_tree = False
    depth_limit: int | None = None
    ignore: list[str] = []
    tree_all = False
    output: str | None = None
    style = HelpTreeStyle.Rich
    color = HelpTreeColor.Auto
    path: list[str] = []

    idx = 0
    while idx < len(argv):
        arg = argv[idx]
        if arg == "--help-tree":
            help_tree = True
        elif arg in ("--tree-depth", "-L"):
            idx += 1
            if idx >= len(argv):
                raise ValueError(f"Missing value for '{arg}'")
            depth_limit = int(argv[idx])
        elif arg in ("--tree-ignore", "-I"):
            idx += 1
            if idx >= len(argv):
                raise ValueError(f"Missing value for '{arg}'")
            ignore.append(argv[idx])
        elif arg in ("--tree-all", "-a"):
            tree_all = True
        elif arg == "--tree-output":
            idx += 1
            if idx >= len(argv):
                raise ValueError("Missing value for '--tree-output'")
            val = argv[idx]
            if val not in (HelpTreeOutputFormat.Text, HelpTreeOutputFormat.Json):
                raise ValueError(f"Invalid --tree-output value: '{val}'")
            output = val
        elif arg == "--tree-style":
            idx += 1
            if idx >= len(argv):
                raise ValueError("Missing value for '--tree-style'")
            val = argv[idx]
            if val not in (HelpTreeStyle.Plain, HelpTreeStyle.Rich):
                raise ValueError(f"Invalid --tree-style value: '{val}'")
            style = val
        elif arg == "--tree-color":
            idx += 1
            if idx >= len(argv):
                raise ValueError("Missing value for '--tree-color'")
            val = argv[idx]
            if val not in (HelpTreeColor.Auto, HelpTreeColor.Always, HelpTreeColor.Never):
                raise ValueError(f"Invalid --tree-color value: '{val}'")
            color = val
        elif arg.startswith("-"):
            pass
        else:
            path.append(arg)
        idx += 1

    if not help_tree:
        return None

    return HelpTreeInvocation(
        opts=HelpTreeOpts(
            depth_limit=depth_limit,
            ignore=ignore,
            tree_all=tree_all,
            output=output or HelpTreeOutputFormat.Text,
            style=style,
            color=color,
            theme=HelpTreeTheme(),
        ),
        path=path,
    )
