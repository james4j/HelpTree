#include <stdio.h>
#include <string.h>
#include "../src/help_tree.h"

static const ht_option_t verbose_opt = {"verbose", "", "--verbose", "Verbose output", false, false, "", false};

static const ht_command_t config_get = {
    "get", "Get a config value", &verbose_opt, 1,
    (const ht_argument_t[]){ {"KEY", "Config key", true, false} }, 1, NULL, 0, false
};
static const ht_command_t config_set = {
    "set", "Set a config value", &verbose_opt, 1,
    (const ht_argument_t[]){ {"KEY", "Config key", true, false}, {"VALUE", "Config value", true, false} }, 2, NULL, 0, false
};
static const ht_command_t config_reload = {
    "reload", "Reload configuration", &verbose_opt, 1, NULL, 0, NULL, 0, false
};
static const ht_command_t config_cmd = {
    "config", "Configuration commands", &verbose_opt, 1, NULL, 0,
    (const ht_command_t[]){config_get, config_set, config_reload}, 3, false
};

static const ht_command_t db_migrate = {"migrate", "Run migrations", NULL, 0, NULL, 0, NULL, 0, false};
static const ht_command_t db_seed = {"seed", "Seed the database", NULL, 0, NULL, 0, NULL, 0, false};
static const ht_command_t db_backup = {"backup", "Backup the database", NULL, 0, NULL, 0, NULL, 0, false};
static const ht_command_t db = {
    "db", "Database commands", NULL, 0, NULL, 0,
    (const ht_command_t[]){db_migrate, db_seed, db_backup}, 3, false
};

static const ht_command_t server = {
    "server", "Server management", &verbose_opt, 1, NULL, 0,
    (const ht_command_t[]){config_cmd, db}, 2, false
};

static const ht_command_t auth_login = {"login", "Log in", NULL, 0, NULL, 0, NULL, 0, false};
static const ht_command_t auth_logout = {"logout", "Log out", NULL, 0, NULL, 0, NULL, 0, false};
static const ht_command_t auth_whoami = {"whoami", "Show current user", NULL, 0, NULL, 0, NULL, 0, false};
static const ht_command_t auth = {
    "auth", "Authentication commands", NULL, 0, NULL, 0,
    (const ht_command_t[]){auth_login, auth_logout, auth_whoami}, 3, false
};

static const ht_command_t req_get = {
    "get", "Send a GET request", &verbose_opt, 1,
    (const ht_argument_t[]){ {"PATH", "Request path", true, false} }, 1, NULL, 0, false
};
static const ht_command_t req_post = {
    "post", "Send a POST request", &verbose_opt, 1,
    (const ht_argument_t[]){ {"PATH", "Request path", true, false} }, 1, NULL, 0, false
};
static const ht_command_t request = {
    "request", "HTTP request commands", &verbose_opt, 1, NULL, 0,
    (const ht_command_t[]){req_get, req_post}, 2, false
};

static const ht_command_t client = {
    "client", "Client operations", &verbose_opt, 1, NULL, 0,
    (const ht_command_t[]){auth, request}, 2, false
};

static const ht_option_t root_opts[] = {
    {"help-tree", "", "--help-tree", "Print a recursive command map derived from framework metadata", false, false, "", false},
    {"tree-depth", "-L", "--tree-depth", "Limit --help-tree recursion depth (Unix tree -L style)", false, true, "", false},
    {"tree-ignore", "-I", "--tree-ignore", "Exclude subtrees/commands from --help-tree output (repeatable)", false, true, "", false},
    {"tree-all", "-a", "--tree-all", "Include hidden subcommands in --help-tree output", false, false, "", false},
    {"tree-output", "", "--tree-output", "Output format (text or json)", false, true, "", false},
    {"tree-style", "", "--tree-style", "Tree text styling mode (rich or plain)", false, true, "", false},
    {"tree-color", "", "--tree-color", "Tree color mode (auto, always, never)", false, true, "", false},
    {"verbose", "", "--verbose", "Verbose output", false, false, "", false},
};

static const ht_command_t root = {
    "deep", "A deeply nested CLI example (3 levels)",
    root_opts, sizeof(root_opts)/sizeof(root_opts[0]), NULL, 0,
    (const ht_command_t[]){server, client}, 2, false
};

int main(int argc, char **argv) {
    ht_invocation_t *inv = ht_parse_invocation(argc - 1, argv + 1);
    if (inv) {
        ht_config_file_t *cfg = ht_load_config("examples/help-tree.json");
        ht_apply_config(&inv->opts, cfg);
        ht_run_for_tree(&root, &inv->opts, inv->path, inv->path_count);
        ht_free_config(cfg);
        ht_free_invocation(inv);
        return 0;
    }
    printf("Run with --help-tree to see the command tree.\n");
    return 0;
}
