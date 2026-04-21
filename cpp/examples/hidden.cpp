#include <CLI/CLI.hpp>
#include "help_tree.hpp"
#include <iostream>
#include <string>
#include <vector>

static help_tree::TreeCommand make_tree() {
    help_tree::TreeCommand root;
    root.name = "hidden";
    root.description = "Example with hidden commands and flags";

    root.options.push_back(help_tree::verboseOption());
    root.options.push_back({"debug",   "", "debug",   "Enable debug mode", false, false, true});
    for (const auto& opt : help_tree::discoveryOptions()) {
        root.options.push_back(opt);
    }

    help_tree::TreeCommand list;
    list.name = "list";
    list.description = "List items";
    root.subcommands.push_back(list);

    help_tree::TreeCommand show;
    show.name = "show";
    show.description = "Show item details";
    show.arguments.push_back({"ID", "Item ID", true, false});
    root.subcommands.push_back(show);

    help_tree::TreeCommand admin;
    admin.name = "admin";
    admin.description = "Administrative commands";
    admin.hidden = true;

    help_tree::TreeCommand users;
    users.name = "users";
    users.description = "List all users";
    admin.subcommands.push_back(users);

    help_tree::TreeCommand stats;
    stats.name = "stats";
    stats.description = "Show system stats";
    admin.subcommands.push_back(stats);

    help_tree::TreeCommand secret;
    secret.name = "secret";
    secret.description = "Secret backdoor";
    secret.hidden = true;
    admin.subcommands.push_back(secret);

    root.subcommands.push_back(admin);

    return root;
}

int main(int argc, char** argv) {
    CLI::App app{"Example with hidden commands and flags"};
    app.name("hidden");

    bool verbose = false;
    app.add_flag("--verbose", verbose, "Verbose output");

    bool debug = false;
    app.add_flag("--debug", debug, "Enable debug mode")->group("");

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

    auto* list = app.add_subcommand("list", "List items");
    auto* show = app.add_subcommand("show", "Show item details");
    std::string show_id;
    show->add_option("ID", show_id, "Item ID")->required();

    auto* admin = app.add_subcommand("admin", "Administrative commands")->group("");
    auto* users = admin->add_subcommand("users", "List all users");
    auto* stats = admin->add_subcommand("stats", "Show system stats");
    auto* secret = admin->add_subcommand("secret", "Secret backdoor")->group("");
    (void)secret; // silence unused warning when not parsing

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

    if (app.got_subcommand(list)) {
        std::cout << "List\n";
    } else if (app.got_subcommand(show)) {
        std::cout << "Show\n";
    } else if (app.got_subcommand(admin)) {
        std::cout << "Admin\n";
    }
    return 0;
}
