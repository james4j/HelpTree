#ifndef HELP_TREE_H
#define HELP_TREE_H

#include <stdbool.h>
#include <stddef.h>

typedef enum {
    HT_TEXT,
    HT_JSON
} ht_output_format_t;

typedef enum {
    HT_PLAIN,
    HT_RICH
} ht_style_t;

typedef enum {
    HT_AUTO,
    HT_ALWAYS,
    HT_NEVER
} ht_color_t;

typedef enum {
    HT_NORMAL,
    HT_BOLD,
    HT_ITALIC,
    HT_BOLD_ITALIC
} ht_emphasis_t;

typedef struct {
    ht_emphasis_t emphasis;
    const char *color_hex;
} ht_token_theme_t;

typedef struct {
    ht_token_theme_t command;
    ht_token_theme_t options;
    ht_token_theme_t description;
} ht_theme_t;

typedef struct {
    int depth_limit;      /* -1 = unlimited */
    char **ignore;
    size_t ignore_count;
    bool tree_all;
    ht_output_format_t output;
    ht_style_t style;
    ht_color_t color;
    ht_theme_t theme;
} ht_opts_t;

typedef struct {
    const char *name;
    const char *short_opt;
    const char *long_opt;
    const char *description;
    bool required;
    bool takes_value;
    const char *default_val;
    bool hidden;
} ht_option_t;

typedef struct {
    const char *name;
    const char *description;
    bool required;
    bool hidden;
} ht_argument_t;

typedef struct ht_command {
    const char *name;
    const char *description;
    const ht_option_t *options;
    size_t option_count;
    const ht_argument_t *arguments;
    size_t argument_count;
    const struct ht_command *subcommands;
    size_t subcommand_count;
    bool hidden;
} ht_command_t;

typedef struct {
    ht_opts_t opts;
    char **path;
    size_t path_count;
} ht_invocation_t;

/* --- defaults --- */
ht_theme_t ht_default_theme(void);
ht_opts_t ht_default_opts(void);

/* --- parsing --- */
ht_invocation_t *ht_parse_invocation(int argc, char **argv);
void ht_free_invocation(ht_invocation_t *inv);

/* --- rendering --- */
char *ht_render_text(const ht_command_t *cmd, const ht_opts_t *opts);
char *ht_render_json(const ht_command_t *cmd, const ht_opts_t *opts);

/* --- convenience --- */
const ht_command_t *ht_find_by_path(const ht_command_t *root, char **path, size_t path_count);
void ht_run_for_tree(const ht_command_t *root, const ht_opts_t *opts, char **path, size_t path_count);

/* --- discovery options helper --- */
extern const ht_option_t ht_discovery_options[];
extern const size_t ht_discovery_option_count;

#endif /* HELP_TREE_H */
