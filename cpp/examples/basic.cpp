#include <CLI/CLI.hpp>
#include "help_tree.hpp"
#include <iostream>
#include <string>
#include <vector>

static help_tree::TreeCommand make_tree() {
    help_tree::TreeCommand root;
    root.name = "basic";
    root.description = "A basic example CLI with nested subcommands";

    root.options.push_back(help_tree::verboseOption());
    for (const auto& opt : help_tree::discoveryOptions()) {
        root.options.push_back(opt);
    }

    help_tree::TreeCommand project;
    project.name = "project";
    project.description = "Manage projects";

    help_tree::TreeCommand project_list;
    project_list.name = "list";
    project_list.description = "List all projects";
    project.subcommands.push_back(project_list);

    help_tree::TreeCommand project_create;
    project_create.name = "create";
    project_create.description = "Create a new project";
    project_create.arguments.push_back({"NAME", "Project name", true, false});
    project.subcommands.push_back(project_create);

    root.subcommands.push_back(project);

    help_tree::TreeCommand task;
    task.name = "task";
    task.description = "Manage tasks";

    help_tree::TreeCommand task_list;
    task_list.name = "list";
    task_list.description = "List all tasks";
    task.subcommands.push_back(task_list);

    help_tree::TreeCommand task_done;
    task_done.name = "done";
    task_done.description = "Mark a task as done";
    task_done.arguments.push_back({"ID", "Task ID", true, false});
    task.subcommands.push_back(task_done);

    root.subcommands.push_back(task);

    return root;
}

int main(int argc, char** argv) {
    CLI::App app{"A basic example CLI with nested subcommands"};
    app.name("basic");

    bool verbose = false;
    app.add_flag("--verbose", verbose, "Verbose output");

    bool help_tree_flag = false;
    app.add_flag("--help-tree", help_tree_flag,
                 "Print a recursive command map derived from framework metadata");

    int tree_depth = 0;
    app.add_option("-L,--tree-depth", tree_depth, "Limit --help-tree recursion depth");

    std::vector<std::string> tree_ignore;
    app.add_option("-I,--tree-ignore", tree_ignore,
                   "Exclude subtrees/commands from --help-tree output");

    bool tree_all = false;
    app.add_flag("-a,--tree-all", tree_all,
                 "Include hidden subcommands in --help-tree output");

    std::string tree_output;
    app.add_option("--tree-output", tree_output, "Output format (text or json)");

    std::string tree_style;
    app.add_option("--tree-style", tree_style, "Tree text styling mode (rich or plain)");

    std::string tree_color;
    app.add_option("--tree-color", tree_color, "Tree color mode (auto, always, never)");

    auto* project = app.add_subcommand("project", "Manage projects");
    auto* project_list = project->add_subcommand("list", "List all projects");
    auto* project_create = project->add_subcommand("create", "Create a new project");
    std::string create_name;
    project_create->add_option("NAME", create_name, "Project name")->required();

    auto* task = app.add_subcommand("task", "Manage tasks");
    auto* task_list = task->add_subcommand("list", "List all tasks");
    auto* task_done = task->add_subcommand("done", "Mark a task as done");
    int done_id = 0;
    task_done->add_option("ID", done_id, "Task ID")->required();

    auto tree = make_tree();
    std::vector<std::string> path;
    auto opts = help_tree::parse_from_argv(argc, argv, path);
    if (opts) {
        auto config = help_tree::loadConfig("examples/help-tree.json");
        if (config) help_tree::applyConfig(*opts, *config);
        help_tree::run(tree, *opts, path);
        return 0;
    }

    CLI11_PARSE(app, argc, argv);

    if (app.got_subcommand(project)) {
        std::cout << "Project command\n";
    } else if (app.got_subcommand(task)) {
        std::cout << "Task command\n";
    }
    return 0;
}
