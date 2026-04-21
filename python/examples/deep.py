#!/usr/bin/env python3
"""Deeply nested CLI example (3 levels)."""

import argparse
import sys
from pathlib import Path

# Allow importing help_tree when running example from any directory
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from help_tree import parse_help_tree_invocation, run_for_parser, load_config, apply_config


def main():
    parser = argparse.ArgumentParser(
        prog="deep",
        description="A deeply nested CLI example (3 levels)",
    )
    parser.add_argument("--verbose", action="store_true", help="Verbose output")
    parser.add_argument("--help-tree", action="store_true", help="Print a recursive command map derived from framework metadata")
    parser.add_argument("-L", "--tree-depth", type=int, help="Limit --help-tree recursion depth")
    parser.add_argument("-I", "--tree-ignore", action="append", help="Exclude subtrees/commands from --help-tree output")
    parser.add_argument("-a", "--tree-all", action="store_true", help="Include hidden subcommands in --help-tree output")
    parser.add_argument("--tree-output", choices=["text", "json"], help="Output format")
    parser.add_argument("--tree-style", choices=["rich", "plain"], help="Tree text styling mode")
    parser.add_argument("--tree-color", choices=["auto", "always", "never"], help="Tree color mode")

    sub = parser.add_subparsers()

    server = sub.add_parser("server", help="Server management")
    server_sub = server.add_subparsers()

    config = server_sub.add_parser("config", help="Configuration commands")
    config_sub = config.add_subparsers()
    config_sub.add_parser("get", help="Get a config value")
    config_sub.add_parser("set", help="Set a config value")
    config_sub.add_parser("reload", help="Reload configuration")

    db = server_sub.add_parser("db", help="Database commands")
    db_sub = db.add_subparsers()
    db_sub.add_parser("migrate", help="Run migrations")
    db_sub.add_parser("seed", help="Seed the database")
    db_sub.add_parser("backup", help="Backup the database")

    client = sub.add_parser("client", help="Client operations")
    client_sub = client.add_subparsers()

    auth = client_sub.add_parser("auth", help="Authentication commands")
    auth_sub = auth.add_subparsers()
    auth_sub.add_parser("login", help="Log in")
    auth_sub.add_parser("logout", help="Log out")
    auth_sub.add_parser("whoami", help="Show current user")

    request = client_sub.add_parser("request", help="HTTP request commands")
    request_sub = request.add_subparsers()
    request_sub.add_parser("get", help="Send a GET request")
    request_sub.add_parser("post", help="Send a POST request")

    invocation = parse_help_tree_invocation(sys.argv[1:])
    if invocation is not None:
        try:
            config = load_config("help-tree.json")
            apply_config(invocation.opts, config)
        except FileNotFoundError:
            pass
        except Exception as e:
            print(f"Warning: failed to load help-tree config: {e}", file=sys.stderr)
        run_for_parser(parser, invocation.opts, invocation.path)
        return

    args = parser.parse_args()
    print(args)


if __name__ == "__main__":
    main()
