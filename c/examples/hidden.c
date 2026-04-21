#include <stdio.h>
#include <string.h>
#include "../src/help_tree.h"

static const ht_command_t list_cmd = {"list", "List items", NULL, 0, NULL, 0, NULL, 0, false};

static const ht_argument_t arg_id = {"ID", "Item ID", true, false};
static const ht_command_t show_cmd = {"show", "Show item details", NULL, 0, &arg_id, 1, NULL, 0, false};

static const ht_command_t admin_users = {"users", "List all users", NULL, 0, NULL, 0, NULL, 0, false};
static const ht_command_t admin_stats = {"stats", "Show system stats", NULL, 0, NULL, 0, NULL, 0, false};
static const ht_command_t admin_secret = {"secret", "Secret backdoor", NULL, 0, NULL, 0, NULL, 0, false};
static const ht_command_t admin = {
    "admin", "Administrative commands", NULL, 0, NULL, 0,
    (const ht_command_t[]){admin_users, admin_stats, admin_secret}, 3, true
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
    {"debug", "", "--debug", "Enable debug mode", false, false, "", true},
};

static const ht_command_t root = {
    "hidden", "An example with hidden commands and flags",
    root_opts, sizeof(root_opts)/sizeof(root_opts[0]), NULL, 0,
    (const ht_command_t[]){list_cmd, show_cmd, admin}, 3, false
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
