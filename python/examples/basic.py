#!/usr/bin/env python3
"""Basic example CLI demonstrating help-tree with argparse."""

import argparse
import sys

sys.path.insert(0, ".")
from help_tree import parse_help_tree_invocation, run_for_parser, load_config, apply_config


def main():
    parser = argparse.ArgumentParser(
        prog="basic",
        description="A basic example CLI with nested subcommands",
    )
    parser.add_argument("--verbose", action="store_true", help="Verbose output")

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
        run_for_parser(parser, invocation.opts, invocation.path)
        return

    args = parser.parse_args()
    print(args)


if __name__ == "__main__":
    main()
