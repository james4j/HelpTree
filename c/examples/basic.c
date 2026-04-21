#include <stdio.h>
#include <string.h>
#include "../src/help_tree.h"

static const ht_argument_t arg_name = {"NAME", "Project name", true, false};
static const ht_argument_t arg_id   = {"ID", "Task ID", true, false};

static const ht_option_t verbose_opt = {"verbose", "", "--verbose", "Verbose output", false, false, "", false};

static const ht_command_t project_list = {
    "list", "List all projects",
    &verbose_opt, 1, NULL, 0, NULL, 0, false
};

static const ht_command_t project_create = {
    "create", "Create a new project",
    &verbose_opt, 1, &arg_name, 1, NULL, 0, false
};

static const ht_command_t project = {
    "project", "Manage projects",
    &verbose_opt, 1, NULL, 0,
    (const ht_command_t[]){project_list, project_create}, 2, false
};

static const ht_command_t task_list = {
    "list", "List all tasks",
    &verbose_opt, 1, NULL, 0, NULL, 0, false
};

static const ht_command_t task_done = {
    "done", "Mark a task as done",
    &verbose_opt, 1, &arg_id, 1, NULL, 0, false
};

static const ht_command_t task = {
    "task", "Manage tasks",
    &verbose_opt, 1, NULL, 0,
    (const ht_command_t[]){task_list, task_done}, 2, false
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
    "basic", "A basic example CLI with nested subcommands",
    root_opts, sizeof(root_opts)/sizeof(root_opts[0]), NULL, 0,
    (const ht_command_t[]){project, task}, 2, false
};

int main(int argc, char **argv) {
    ht_invocation_t *inv = ht_parse_invocation(argc - 1, argv + 1);
    if (inv) {
        ht_run_for_tree(&root, &inv->opts, inv->path, inv->path_count);
        ht_free_invocation(inv);
        return 0;
    }
    printf("Run with --help-tree to see the command tree.\n");
    return 0;
}
