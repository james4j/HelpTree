#!/usr/bin/env julia

using ArgParse
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using HelpTree

function build_settings()
    s = ArgParseSettings(prog = "deep", description = "A deeply nested CLI example (3 levels)")

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
        "server"
            help = "Server management"
            action = :command
        "client"
            help = "Client operations"
            action = :command
    end

    @add_arg_table! s["server"] begin
        "config"
            help = "Configuration commands"
            action = :command
        "db"
            help = "Database commands"
            action = :command
    end

    @add_arg_table! s["server"]["config"] begin
        "get"
            help = "Get a config value"
            action = :command
        "set"
            help = "Set a config value"
            action = :command
        "reload"
            help = "Reload configuration"
            action = :command
    end

    @add_arg_table! s["server"]["config"]["get"] begin
        "key"
            help = "Config key"
            required = true
    end

    @add_arg_table! s["server"]["config"]["set"] begin
        "key"
            help = "Config key"
            required = true
        "value"
            help = "Config value"
            required = true
    end

    @add_arg_table! s["server"]["db"] begin
        "migrate"
            help = "Run migrations"
            action = :command
        "seed"
            help = "Seed the database"
            action = :command
        "backup"
            help = "Backup the database"
            action = :command
    end

    @add_arg_table! s["client"] begin
        "auth"
            help = "Authentication commands"
            action = :command
        "request"
            help = "HTTP request commands"
            action = :command
    end

    @add_arg_table! s["client"]["auth"] begin
        "login"
            help = "Log in"
            action = :command
        "logout"
            help = "Log out"
            action = :command
        "whoami"
            help = "Show current user"
            action = :command
    end

    @add_arg_table! s["client"]["request"] begin
        "get"
            help = "Send a GET request"
            action = :command
        "post"
            help = "Send a POST request"
            action = :command
    end

    @add_arg_table! s["client"]["request"]["get"] begin
        "path"
            help = "URL path"
            required = true
    end

    @add_arg_table! s["client"]["request"]["post"] begin
        "path"
            help = "URL path"
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
