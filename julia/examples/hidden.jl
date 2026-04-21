#!/usr/bin/env julia

using ArgParse
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using HelpTree

function build_settings()
    s = ArgParseSettings(prog = "hidden", description = "Example with hidden commands and flags")

    @add_arg_table! s begin
        "--verbose"
            help = "Verbose output"
            action = :store_true
        "--debug"
            help = ""
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
        "list"
            help = "List items"
            action = :command
        "show"
            help = "Show item details"
            action = :command
        "admin"
            help = ""
            action = :command
    end

    @add_arg_table! s["show"] begin
        "id"
            help = "Item ID"
            required = true
    end

    @add_arg_table! s["admin"] begin
        "users"
            help = "List all users"
            action = :command
        "stats"
            help = "Show system stats"
            action = :command
        "secret"
            help = ""
            action = :command
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
