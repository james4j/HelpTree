#!/usr/bin/env python3
"""Example with hidden commands and flags."""

import argparse
import sys

sys.path.insert(0, ".")
from help_tree import parse_help_tree_invocation, run_for_parser, load_config, apply_config


def main():
    parser = argparse.ArgumentParser(
        prog="hidden",
        description="Example with hidden commands and flags",
    )
    parser.add_argument("--verbose", action="store_true", help="Verbose output")
    parser.add_argument("--help-tree", action="store_true", help="Print a recursive command map derived from framework metadata")
    parser.add_argument("-L", "--tree-depth", type=int, help="Limit --help-tree recursion depth")
    parser.add_argument("-I", "--tree-ignore", action="append", help="Exclude subtrees/commands from --help-tree output")
    parser.add_argument("-a", "--tree-all", action="store_true", help="Include hidden subcommands in --help-tree output")
    parser.add_argument("--tree-output", choices=["text", "json"], help="Output format")
    parser.add_argument("--tree-style", choices=["rich", "plain"], help="Tree text styling mode")
    parser.add_argument("--tree-color", choices=["auto", "always", "never"], help="Tree color mode")
    parser.add_argument(
        "--debug", action="store_true", help=argparse.SUPPRESS
    )

    sub = parser.add_subparsers()

    sub.add_parser("list", help="List items")
    show = sub.add_parser("show", help="Show item details")
    show.add_argument("id", help="Item ID")

    admin = sub.add_parser("admin", help=argparse.SUPPRESS)
    admin_sub = admin.add_subparsers()
    admin_sub.add_parser("users", help="List all users")
    admin_sub.add_parser("stats", help="Show system stats")
    admin_sub.add_parser("secret", help=argparse.SUPPRESS)

    invocation = parse_help_tree_invocation(sys.argv[1:])
    if invocation is not None:
        try:
            config = load_config("help-tree.json")
            apply_config(invocation.opts, config)
        except FileNotFoundError:
            pass
        run_for_parser(parser, invocation.opts, invocation.path)
        return

    args = parser.parse_args()
    print(args)


if __name__ == "__main__":
    main()
