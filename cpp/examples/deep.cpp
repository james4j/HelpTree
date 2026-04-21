#include <CLI/CLI.hpp>
#include "help_tree.hpp"
#include <iostream>
#include <string>
#include <vector>

static help_tree::TreeCommand make_tree() {
    help_tree::TreeCommand root;
    root.name = "deep";
    root.description = "A deeply nested CLI example (3 levels)";

    root.options.push_back(help_tree::verboseOption());
    for (const auto& opt : help_tree::discoveryOptions()) {
        root.options.push_back(opt);
    }

    auto add_leaf = [&](help_tree::TreeCommand& parent, const std::string& name,
                        const std::string& desc,
                        const std::vector<help_tree::TreeArgument>& args = {}) {
        help_tree::TreeCommand cmd;
        cmd.name = name;
        cmd.description = desc;
        cmd.arguments = args;
        parent.subcommands.push_back(cmd);
    };

    help_tree::TreeCommand server;
    server.name = "server";
    server.description = "Server management";

    help_tree::TreeCommand config;
    config.name = "config";
    config.description = "Configuration commands";
    add_leaf(config, "get",    "Get a config value",    {{"KEY", "Config key", true, false}});
    add_leaf(config, "set",    "Set a config value",    {{"KEY", "Config key", true, false}, {"VALUE", "Config value", true, false}});
    add_leaf(config, "reload", "Reload configuration");
    server.subcommands.push_back(config);

    help_tree::TreeCommand db;
    db.name = "db";
    db.description = "Database commands";
    add_leaf(db, "migrate", "Run migrations");
    add_leaf(db, "seed",    "Seed the database");
    add_leaf(db, "backup",  "Backup the database");
    server.subcommands.push_back(db);

    root.subcommands.push_back(server);

    help_tree::TreeCommand client;
    client.name = "client";
    client.description = "Client operations";

    help_tree::TreeCommand auth;
    auth.name = "auth";
    auth.description = "Authentication commands";
    add_leaf(auth, "login",  "Log in");
    add_leaf(auth, "logout", "Log out");
    add_leaf(auth, "whoami", "Show current user");
    client.subcommands.push_back(auth);

    help_tree::TreeCommand request;
    request.name = "request";
    request.description = "HTTP request commands";
    add_leaf(request, "get",  "Send a GET request",  {{"PATH", "URL path", true, false}});
    add_leaf(request, "post", "Send a POST request", {{"PATH", "URL path", true, false}});
    client.subcommands.push_back(request);

    root.subcommands.push_back(client);

    return root;
}

int main(int argc, char** argv) {
    CLI::App app{"A deeply nested CLI example (3 levels)"};
    app.name("deep");

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

    auto* server = app.add_subcommand("server", "Server management");
    auto* config = server->add_subcommand("config", "Configuration commands");
    auto* config_get = config->add_subcommand("get", "Get a config value");
    std::string key;
    config_get->add_option("KEY", key, "Config key")->required();
    auto* config_set = config->add_subcommand("set", "Set a config value");
    std::string value;
    config_set->add_option("KEY", key, "Config key")->required();
    config_set->add_option("VALUE", value, "Config value")->required();
    auto* config_reload = config->add_subcommand("reload", "Reload configuration");

    auto* db = server->add_subcommand("db", "Database commands");
    db->add_subcommand("migrate", "Run migrations");
    db->add_subcommand("seed", "Seed the database");
    db->add_subcommand("backup", "Backup the database");

    auto* client = app.add_subcommand("client", "Client operations");
    auto* auth = client->add_subcommand("auth", "Authentication commands");
    auth->add_subcommand("login", "Log in");
    auth->add_subcommand("logout", "Log out");
    auth->add_subcommand("whoami", "Show current user");

    auto* request = client->add_subcommand("request", "HTTP request commands");
    auto* request_get = request->add_subcommand("get", "Send a GET request");
    std::string path_arg;
    request_get->add_option("PATH", path_arg, "URL path")->required();
    auto* request_post = request->add_subcommand("post", "Send a POST request");
    request_post->add_option("PATH", path_arg, "URL path")->required();

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

    if (app.got_subcommand(server)) {
        std::cout << "Server command\n";
    } else if (app.got_subcommand(client)) {
        std::cout << "Client command\n";
    }
    return 0;
}
