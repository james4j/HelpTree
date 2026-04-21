#!/usr/bin/env python3
"""Basic example CLI demonstrating help-tree with argparse."""

import argparse
import sys
from pathlib import Path

# Allow importing help_tree when running example from any directory
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from help_tree import parse_help_tree_invocation, run_for_parser, load_config, apply_config


def main():
    parser = argparse.ArgumentParser(
        prog="basic",
        description="A basic example CLI with nested subcommands",
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

    project = sub.add_parser("project", help="Manage projects")
    project_sub = project.add_subparsers()
    project_sub.add_parser("list", help="List all projects")
    create = project_sub.add_parser("create", help="Create a new project")
    create.add_argument("name", help="Project name")

    task = sub.add_parser("task", help="Manage tasks")
    task_sub = task.add_subparsers()
    task_sub.add_parser("list", help="List all tasks")
    done = task_sub.add_parser("done", help="Mark a task as done")
    done.add_argument("id", type=int, help="Task ID")

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
