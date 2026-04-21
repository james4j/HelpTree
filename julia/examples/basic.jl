#!/usr/bin/env julia

using ArgParse
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using HelpTree

function build_settings()
    s = ArgParseSettings(prog = "basic", description = "A basic example CLI with nested subcommands")

    @add_arg_table! s begin
        "--verbose"
            help = "Verbose output"
            action = :store_true
        "--help-tree"
            help = "Print a recursive command map derived from framework metadata"
            action = :store_true
        "-L", "--tree-depth"
            help = "Limit --help-tree recursion depth"
            arg_type = Int
        "-I", "--tree-ignore"
            help = "Exclude subtrees/commands from --help-tree output"
        "-a", "--tree-all"
            help = "Include hidden subcommands in --help-tree output"
            action = :store_true
        "--tree-output"
            help = "Output format (text or json)"
        "--tree-style"
            help = "Tree text styling mode (rich or plain)"
        "--tree-color"
            help = "Tree color mode (auto, always, never)"
        "project"
            help = "Manage projects"
            action = :command
        "task"
            help = "Manage tasks"
            action = :command
    end

    @add_arg_table! s["project"] begin
        "list"
            help = "List all projects"
            action = :command
        "create"
            help = "Create a new project"
            action = :command
    end

    @add_arg_table! s["project"]["create"] begin
        "name"
            help = "Project name"
            required = true
    end

    @add_arg_table! s["task"] begin
        "list"
            help = "List all tasks"
            action = :command
        "done"
            help = "Mark a task as done"
            action = :command
    end

    @add_arg_table! s["task"]["done"] begin
        "id"
            help = "Task ID"
            arg_type = Int
            required = true
    end

    return s
end

function main()
    s = build_settings()

    invocation = HelpTree.parse_help_tree_invocation(ARGS)
    if invocation !== nothing
        config_path = joinpath(@__DIR__, "..", "help-tree.json")
        if isfile(config_path)
            config = HelpTree.load_config(config_path)
            HelpTree.apply_config!(invocation.opts, config)
        end
        HelpTree.run_for_argparse(s, invocation.opts, invocation.path)
        return
    end

    args = parse_args(s)
    println(args)
end

main()
