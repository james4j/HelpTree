#include "help_tree.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define TREE_ALIGN_WIDTH 28
#define MIN_DOTS 4

/* ------------------------------------------------------------------ */
/* Discovery options                                                   */
/* ------------------------------------------------------------------ */

const ht_option_t ht_discovery_options[] = {
    {"help-tree", "", "--help-tree", "Print a recursive command map derived from framework metadata", false, false, "", false},
    {"tree-depth", "-L", "--tree-depth", "Limit --help-tree recursion depth (Unix tree -L style)", false, true, "", false},
    {"tree-ignore", "-I", "--tree-ignore", "Exclude subtrees/commands from --help-tree output (repeatable)", false, true, "", false},
    {"tree-all", "-a", "--tree-all", "Include hidden subcommands in --help-tree output", false, false, "", false},
    {"tree-output", "", "--tree-output", "Output format (text or json)", false, true, "", false},
    {"tree-style", "", "--tree-style", "Tree text styling mode (rich or plain)", false, true, "", false},
    {"tree-color", "", "--tree-color", "Tree color mode (auto, always, never)", false, true, "", false},
};

const size_t ht_discovery_option_count = sizeof(ht_discovery_options) / sizeof(ht_discovery_options[0]);

const ht_option_t ht_verbose_option = {"verbose", "", "--verbose", "Verbose output", false, false, "", false};

/* ------------------------------------------------------------------ */
/* Defaults                                                            */
/* ------------------------------------------------------------------ */

ht_theme_t ht_default_theme(void) {
    ht_theme_t t;
    t.command.emphasis = HT_BOLD;
    t.command.color_hex = "#7ee7e6";
    t.options.emphasis = HT_NORMAL;
    t.options.color_hex = NULL;
    t.description.emphasis = HT_ITALIC;
    t.description.color_hex = "#90a2af";
    return t;
}

ht_opts_t ht_default_opts(void) {
    ht_opts_t o;
    o.depth_limit = -1;
    o.ignore = NULL;
    o.ignore_count = 0;
    o.tree_all = false;
    o.output = HT_TEXT;
    o.style = HT_RICH;
    o.color = HT_AUTO;
    o.theme = ht_default_theme();
    return o;
}

/* ------------------------------------------------------------------ */
/* Helpers                                                             */
/* ------------------------------------------------------------------ */

static bool should_use_color(const ht_opts_t *opts) {
    switch (opts->color) {
        case HT_ALWAYS: return true;
        case HT_NEVER:  return false;
        case HT_AUTO:   return isatty(STDOUT_FILENO);
    }
    return false;
}

static bool parse_hex_rgb(const char *hex, int *r, int *g, int *b) {
    const char *h = hex;
    if (*h == '#') h++;
    if (strlen(h) != 6) return false;
    if (sscanf(h, "%2x%2x%2x", r, g, b) != 3) return false;
    return true;
}

/* Write styled text into buf (size buflen). Returns bytes written. */
static size_t style_text(char *buf, size_t buflen, const char *text,
                         const ht_token_theme_t *token, const ht_opts_t *opts) {
    if (opts->style == HT_PLAIN ||
        (token->emphasis == HT_NORMAL && token->color_hex == NULL)) {
        return (size_t)snprintf(buf, buflen, "%s", text);
    }

    char codes[64];
    size_t c_off = 0;

    switch (token->emphasis) {
        case HT_BOLD:        c_off += sprintf(codes + c_off, "1"); break;
        case HT_ITALIC:      c_off += sprintf(codes + c_off, "3"); break;
        case HT_BOLD_ITALIC: c_off += sprintf(codes + c_off, "1;3"); break;
        default: break;
    }

    if (should_use_color(opts) && token->color_hex) {
        int r, g, b;
        if (parse_hex_rgb(token->color_hex, &r, &g, &b)) {
            if (c_off > 0) codes[c_off++] = ';';
            c_off += sprintf(codes + c_off, "38;2;%d;%d;%d", r, g, b);
        }
    }

    if (c_off == 0) return (size_t)snprintf(buf, buflen, "%s", text);
    return (size_t)snprintf(buf, buflen, "\x1b[%sm%s\x1b[0m", codes, text);
}

static bool should_skip_option(const ht_option_t *opt, bool tree_all) {
    if (tree_all) return false;
    if (opt->hidden) return true;
    if (strcmp(opt->name, "help") == 0 || strcmp(opt->name, "version") == 0) return true;
    return false;
}

static bool should_skip_argument(const ht_argument_t *arg, bool tree_all) {
    if (tree_all) return false;
    if (arg->hidden) return true;
    return false;
}

static bool should_skip_command(const ht_command_t *cmd, const ht_opts_t *opts) {
    if (strcmp(cmd->name, "help") == 0) return true;
    for (size_t i = 0; i < opts->ignore_count; i++) {
        if (strcmp(cmd->name, opts->ignore[i]) == 0) return true;
    }
    if (!opts->tree_all && cmd->hidden) return true;
    return false;
}

/* Build signature suffix into buf, return length */
static size_t command_signature(char *buf, size_t buflen,
                                const ht_command_t *cmd, bool tree_all) {
    size_t off = 0;
    for (size_t i = 0; i < cmd->argument_count; i++) {
        if (should_skip_argument(&cmd->arguments[i], tree_all)) continue;
        const char *fmt = cmd->arguments[i].required ? " <%s>" : " [%s]";
        off += (size_t)snprintf(buf + off, buflen - off, fmt, cmd->arguments[i].name);
    }
    bool has_flags = false;
    for (size_t i = 0; i < cmd->option_count; i++) {
        if (!should_skip_option(&cmd->options[i], tree_all)) {
            has_flags = true;
            break;
        }
    }
    if (has_flags) {
        off += (size_t)snprintf(buf + off, buflen - off, " [flags]");
    }
    return off;
}

/* ------------------------------------------------------------------ */
/* Dynamic string builder                                              */
/* ------------------------------------------------------------------ */

typedef struct {
    char *data;
    size_t len;
    size_t cap;
} sb_t;

static void sb_init(sb_t *sb) {
    sb->cap = 256;
    sb->data = malloc(sb->cap);
    if (!sb->data) {
        fprintf(stderr, "help_tree: out of memory\n");
        abort();
    }
    sb->len = 0;
    sb->data[0] = '\0';
}

static void sb_ensure(sb_t *sb, size_t need) {
    if (sb->len + need + 1 > sb->cap) {
        while (sb->len + need + 1 > sb->cap) sb->cap *= 2;
        char *new_data = realloc(sb->data, sb->cap);
        if (!new_data) {
            fprintf(stderr, "help_tree: out of memory\n");
            abort();
        }
        sb->data = new_data;
    }
}

static void sb_append(sb_t *sb, const char *s) {
    size_t n = strlen(s);
    sb_ensure(sb, n);
    memcpy(sb->data + sb->len, s, n);
    sb->len += n;
    sb->data[sb->len] = '\0';
}

static void sb_appendn(sb_t *sb, char c, size_t n) {
    sb_ensure(sb, n);
    memset(sb->data + sb->len, c, n);
    sb->len += n;
    sb->data[sb->len] = '\0';
}

/* ------------------------------------------------------------------ */
/* Text rendering                                                      */
/* ------------------------------------------------------------------ */

static void render_text_lines(sb_t *out, const ht_command_t *cmd,
                              const char *prefix, int depth,
                              const ht_opts_t *opts) {
    size_t item_count = 0;
    for (size_t i = 0; i < cmd->subcommand_count; i++) {
        if (!should_skip_command(&cmd->subcommands[i], opts)) item_count++;
    }
    if (item_count == 0) return;

    bool at_limit = opts->depth_limit >= 0 && depth >= opts->depth_limit;

    size_t idx = 0;
    for (size_t i = 0; i < cmd->subcommand_count; i++) {
        const ht_command_t *sub = &cmd->subcommands[i];
        if (should_skip_command(sub, opts)) continue;
        bool is_last = idx == item_count - 1;
        idx++;

        const char *branch = is_last ? "└── " : "├── ";

        char sig_buf[128];
        command_signature(sig_buf, sizeof(sig_buf), sub, opts->tree_all);
        char signature[256];
        snprintf(signature, sizeof(signature), "%s%s", sub->name, sig_buf);

        char styled_name[256], styled_suffix[256];
        style_text(styled_name, sizeof(styled_name), sub->name, &opts->theme.command, opts);
        style_text(styled_suffix, sizeof(styled_suffix), sig_buf, &opts->theme.options, opts);

        sb_append(out, prefix);
        sb_append(out, branch);
        sb_append(out, styled_name);
        sb_append(out, styled_suffix);

        if (sub->description && sub->description[0]) {
            int dots_len = TREE_ALIGN_WIDTH - (int)strlen(signature);
            if (dots_len < MIN_DOTS) dots_len = MIN_DOTS;
            sb_append(out, " ");
            sb_appendn(out, '.', (size_t)dots_len);
            sb_append(out, " ");
            char styled_desc[256];
            style_text(styled_desc, sizeof(styled_desc), sub->description, &opts->theme.description, opts);
            sb_append(out, styled_desc);
        }
        sb_append(out, "\n");

        if (at_limit) continue;

        const char *ext = is_last ? "    " : "│   ";
        char next_prefix[256];
        snprintf(next_prefix, sizeof(next_prefix), "%s%s", prefix, ext);
        render_text_lines(out, sub, next_prefix, depth + 1, opts);
    }
}

char *ht_render_text(const ht_command_t *cmd, const ht_opts_t *opts) {
    sb_t out;
    sb_init(&out);

    char styled[256];
    style_text(styled, sizeof(styled), cmd->name, &opts->theme.command, opts);
    sb_append(&out, styled);
    sb_append(&out, "\n");

    for (size_t i = 0; i < cmd->option_count; i++) {
        if (should_skip_option(&cmd->options[i], opts->tree_all)) continue;
        const ht_option_t *opt = &cmd->options[i];
        char meta[64];
        if (opt->short_opt[0] && opt->long_opt[0]) {
            snprintf(meta, sizeof(meta), "%s, %s", opt->short_opt, opt->long_opt);
        } else if (opt->long_opt[0]) {
            snprintf(meta, sizeof(meta), "%s", opt->long_opt);
        } else if (opt->short_opt[0]) {
            snprintf(meta, sizeof(meta), "%s", opt->short_opt);
        } else {
            snprintf(meta, sizeof(meta), "%s", opt->name);
        }

        char smeta[256], sdesc[256];
        style_text(smeta, sizeof(smeta), meta, &opts->theme.options, opts);
        style_text(sdesc, sizeof(sdesc), opt->description, &opts->theme.description, opts);
        sb_append(&out, "  ");
        sb_append(&out, smeta);
        sb_append(&out, " … ");
        sb_append(&out, sdesc);
        sb_append(&out, "\n");
    }

    if (cmd->subcommand_count > 0) {
        sb_append(&out, "\n");
        render_text_lines(&out, cmd, "", 0, opts);
    }

    return out.data; /* caller frees */
}

/* ------------------------------------------------------------------ */
/* JSON rendering                                                      */
/* ------------------------------------------------------------------ */

static void json_escape(sb_t *out, const char *s) {
    for (; *s; s++) {
        switch (*s) {
            case '"': sb_append(out, "\\\""); break;
            case '\\': sb_append(out, "\\\\"); break;
            case '\b': sb_append(out, "\\b"); break;
            case '\f': sb_append(out, "\\f"); break;
            case '\n': sb_append(out, "\\n"); break;
            case '\r': sb_append(out, "\\r"); break;
            case '\t': sb_append(out, "\\t"); break;
            default: {
                char buf[2] = {*s, '\0'};
                sb_append(out, buf);
            }
        }
    }
}

static void option_to_json(sb_t *out, const ht_option_t *opt) {
    sb_append(out, "{\"type\":\"option\",\"name\":\"");
    json_escape(out, opt->name);
    sb_append(out, "\"");
    if (opt->description && opt->description[0]) {
        sb_append(out, ",\"description\":\"");
        json_escape(out, opt->description);
        sb_append(out, "\"");
    }
    if (opt->short_opt && opt->short_opt[0]) {
        sb_append(out, ",\"short\":\"");
        json_escape(out, opt->short_opt);
        sb_append(out, "\"");
    }
    if (opt->long_opt && opt->long_opt[0]) {
        sb_append(out, ",\"long\":\"");
        json_escape(out, opt->long_opt);
        sb_append(out, "\"");
    }
    if (opt->default_val && opt->default_val[0]) {
        sb_append(out, ",\"default\":\"");
        json_escape(out, opt->default_val);
        sb_append(out, "\"");
    }
    sb_append(out, ",\"required\":");
    sb_append(out, opt->required ? "true" : "false");
    sb_append(out, ",\"takes_value\":");
    sb_append(out, opt->takes_value ? "true" : "false");
    sb_append(out, "}");
}

static void argument_to_json(sb_t *out, const ht_argument_t *arg) {
    sb_append(out, "{\"type\":\"argument\",\"name\":\"");
    json_escape(out, arg->name);
    sb_append(out, "\"");
    if (arg->description && arg->description[0]) {
        sb_append(out, ",\"description\":\"");
        json_escape(out, arg->description);
        sb_append(out, "\"");
    }
    sb_append(out, ",\"required\":");
    sb_append(out, arg->required ? "true" : "false");
    sb_append(out, "}");
}

static void cmd_to_json(sb_t *out, const ht_command_t *cmd,
                        const ht_opts_t *opts, int depth);

static void cmd_to_json_internal(sb_t *out, const ht_command_t *cmd,
                                 const ht_opts_t *opts, int depth) {
    sb_append(out, "{\"type\":\"command\",\"name\":\"");
    json_escape(out, cmd->name);
    sb_append(out, "\"");
    if (cmd->description && cmd->description[0]) {
        sb_append(out, ",\"description\":\"");
        json_escape(out, cmd->description);
        sb_append(out, "\"");
    }

    /* options */
    size_t opt_count = 0;
    for (size_t i = 0; i < cmd->option_count; i++) {
        if (!should_skip_option(&cmd->options[i], opts->tree_all)) opt_count++;
    }
    if (opt_count > 0) {
        sb_append(out, ",\"options\":[");
        bool first = true;
        for (size_t i = 0; i < cmd->option_count; i++) {
            if (should_skip_option(&cmd->options[i], opts->tree_all)) continue;
            if (!first) sb_append(out, ",");
            first = false;
            option_to_json(out, &cmd->options[i]);
        }
        sb_append(out, "]");
    }

    /* arguments */
    size_t arg_count = 0;
    for (size_t i = 0; i < cmd->argument_count; i++) {
        if (!should_skip_argument(&cmd->arguments[i], opts->tree_all)) arg_count++;
    }
    if (arg_count > 0) {
        sb_append(out, ",\"arguments\":[");
        bool first = true;
        for (size_t i = 0; i < cmd->argument_count; i++) {
            if (should_skip_argument(&cmd->arguments[i], opts->tree_all)) continue;
            if (!first) sb_append(out, ",");
            first = false;
            argument_to_json(out, &cmd->arguments[i]);
        }
        sb_append(out, "]");
    }

    bool can_recurse = opts->depth_limit < 0 || depth < opts->depth_limit;
    if (can_recurse) {
        size_t sub_count = 0;
        for (size_t i = 0; i < cmd->subcommand_count; i++) {
            if (!should_skip_command(&cmd->subcommands[i], opts)) sub_count++;
        }
        if (sub_count > 0) {
            sb_append(out, ",\"subcommands\":[");
            bool first = true;
            for (size_t i = 0; i < cmd->subcommand_count; i++) {
                if (should_skip_command(&cmd->subcommands[i], opts)) continue;
                if (!first) sb_append(out, ",");
                first = false;
                cmd_to_json(out, &cmd->subcommands[i], opts, depth + 1);
            }
            sb_append(out, "]");
        }
    }

    sb_append(out, "}");
}

static void cmd_to_json(sb_t *out, const ht_command_t *cmd,
                        const ht_opts_t *opts, int depth) {
    cmd_to_json_internal(out, cmd, opts, depth);
}

char *ht_render_json(const ht_command_t *cmd, const ht_opts_t *opts) {
    sb_t out;
    sb_init(&out);
    cmd_to_json(&out, cmd, opts, 0);
    sb_append(&out, "\n");
    return out.data;
}

/* ------------------------------------------------------------------ */
/* Parsing                                                             */
/* ------------------------------------------------------------------ */

ht_invocation_t *ht_parse_invocation(int argc, char **argv) {
    bool help_tree = false;
    int depth_limit = -1;
    char **ignore = NULL;
    size_t ignore_count = 0;
    size_t ignore_cap = 0;
    bool tree_all = false;
    ht_output_format_t output = HT_TEXT;
    ht_style_t style = HT_RICH;
    ht_color_t color = HT_AUTO;
    char **path = NULL;
    size_t path_count = 0;
    size_t path_cap = 0;

    for (int i = 0; i < argc; i++) {
        char *arg = argv[i];
        if (strcmp(arg, "--help-tree") == 0) {
            help_tree = true;
        } else if ((strcmp(arg, "--tree-depth") == 0 || strcmp(arg, "-L") == 0) && i + 1 < argc) {
            char *endptr = NULL;
            long val = strtol(argv[++i], &endptr, 10);
            if (endptr != argv[i] && *endptr == '\0' && val >= 0) {
                depth_limit = (int)val;
            }
        } else if ((strcmp(arg, "--tree-ignore") == 0 || strcmp(arg, "-I") == 0) && i + 1 < argc) {
            if (ignore_count == ignore_cap) {
                ignore_cap = ignore_cap ? ignore_cap * 2 : 4;
                char **new_ignore = realloc(ignore, ignore_cap * sizeof(char *));
                if (!new_ignore) {
                    fprintf(stderr, "help_tree: out of memory\n");
                    abort();
                }
                ignore = new_ignore;
            }
            ignore[ignore_count++] = argv[++i];
        } else if (strcmp(arg, "--tree-all") == 0 || strcmp(arg, "-a") == 0) {
            tree_all = true;
        } else if (strcmp(arg, "--tree-output") == 0 && i + 1 < argc) {
            char *v = argv[++i];
            if (strcmp(v, "json") == 0) output = HT_JSON;
            else output = HT_TEXT;
        } else if (strcmp(arg, "--tree-style") == 0 && i + 1 < argc) {
            char *v = argv[++i];
            if (strcmp(v, "plain") == 0) style = HT_PLAIN;
            else style = HT_RICH;
        } else if (strcmp(arg, "--tree-color") == 0 && i + 1 < argc) {
            char *v = argv[++i];
            if (strcmp(v, "always") == 0) color = HT_ALWAYS;
            else if (strcmp(v, "never") == 0) color = HT_NEVER;
            else color = HT_AUTO;
        } else if (arg[0] != '-') {
            if (path_count == path_cap) {
                path_cap = path_cap ? path_cap * 2 : 4;
                char **new_path = realloc(path, path_cap * sizeof(char *));
                if (!new_path) {
                    fprintf(stderr, "help_tree: out of memory\n");
                    abort();
                }
                path = new_path;
            }
            path[path_count++] = arg;
        }
    }

    if (!help_tree) {
        free(ignore);
        free(path);
        return NULL;
    }

    ht_invocation_t *inv = malloc(sizeof(ht_invocation_t));
    if (!inv) {
        fprintf(stderr, "help_tree: out of memory\n");
        abort();
    }
    inv->opts = ht_default_opts();
    inv->opts.depth_limit = depth_limit;
    inv->opts.ignore = ignore;
    inv->opts.ignore_count = ignore_count;
    inv->opts.tree_all = tree_all;
    inv->opts.output = output;
    inv->opts.style = style;
    inv->opts.color = color;
    inv->path = path;
    inv->path_count = path_count;
    return inv;
}

void ht_free_invocation(ht_invocation_t *inv) {
    if (!inv) return;
    free(inv->opts.ignore);
    free(inv->path);
    free(inv);
}

/* ------------------------------------------------------------------ */
/* Minimal JSON parser for theme config                                */
/* ------------------------------------------------------------------ */

static void json_skip_ws(const char **p) {
    while (**p == ' ' || **p == '\n' || **p == '\r' || **p == '\t') (*p)++;
}

static bool json_parse_string(const char **p, char *out, size_t outlen) {
    json_skip_ws(p);
    if (**p != '"') return false;
    (*p)++;
    size_t i = 0;
    while (**p && **p != '"') {
        if (i + 1 < outlen) out[i] = **p;
        i++;
        (*p)++;
    }
    if (**p == '"') (*p)++;
    if (i < outlen) out[i] = '\0';
    else out[outlen - 1] = '\0';
    return true;
}

static bool json_expect(const char **p, char c) {
    json_skip_ws(p);
    if (**p == c) { (*p)++; return true; }
    return false;
}

static ht_emphasis_t parse_emphasis(const char *s) {
    if (strcmp(s, "bold") == 0) return HT_BOLD;
    if (strcmp(s, "italic") == 0) return HT_ITALIC;
    if (strcmp(s, "bold_italic") == 0) return HT_BOLD_ITALIC;
    return HT_NORMAL;
}

static char *json_strdup(const char *s) {
    if (!s) return NULL;
    char *copy = malloc(strlen(s) + 1);
    if (copy) strcpy(copy, s);
    return copy;
}

static bool json_parse_token_theme(const char **p, ht_token_theme_t *token) {
    if (!json_expect(p, '{')) return false;
    token->emphasis = HT_NORMAL;
    token->color_hex = NULL;
    while (1) {
        json_skip_ws(p);
        if (**p == '}') { (*p)++; break; }
        char key[32], val[32];
        if (!json_parse_string(p, key, sizeof(key))) return false;
        if (!json_expect(p, ':')) return false;
        if (!json_parse_string(p, val, sizeof(val))) return false;
        if (strcmp(key, "emphasis") == 0) token->emphasis = parse_emphasis(val);
        else if (strcmp(key, "color_hex") == 0) token->color_hex = json_strdup(val);
        json_skip_ws(p);
        if (**p == ',') { (*p)++; continue; }
        else if (**p == '}') { (*p)++; break; }
        else return false;
    }
    return true;
}

static bool json_parse_theme(const char **p, ht_theme_t *theme) {
    if (!json_expect(p, '{')) return false;
    *theme = ht_default_theme();
    /* strdup the default strings so they can all be freed uniformly */
    theme->command.color_hex = json_strdup(theme->command.color_hex);
    theme->options.color_hex = json_strdup(theme->options.color_hex);
    theme->description.color_hex = json_strdup(theme->description.color_hex);
    while (1) {
        json_skip_ws(p);
        if (**p == '}') { (*p)++; break; }
        char key[32];
        if (!json_parse_string(p, key, sizeof(key))) return false;
        if (!json_expect(p, ':')) return false;
        ht_token_theme_t token;
        if (!json_parse_token_theme(p, &token)) return false;
        if (strcmp(key, "command") == 0) {
            free((void*)theme->command.color_hex);
            theme->command = token;
        }
        else if (strcmp(key, "options") == 0) {
            free((void*)theme->options.color_hex);
            theme->options = token;
        }
        else if (strcmp(key, "description") == 0) {
            free((void*)theme->description.color_hex);
            theme->description = token;
        }
        json_skip_ws(p);
        if (**p == ',') { (*p)++; continue; }
        else if (**p == '}') { (*p)++; break; }
        else return false;
    }
    return true;
}

ht_config_file_t *ht_load_config(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return NULL; }
    long len = ftell(f);
    if (len < 0) { fclose(f); return NULL; }
    if (fseek(f, 0, SEEK_SET) != 0) { fclose(f); return NULL; }
    char *data = malloc((size_t)len + 1);
    if (!data) { fclose(f); return NULL; }
    size_t read = fread(data, 1, (size_t)len, f);
    fclose(f);
    data[read] = '\0';

    ht_theme_t theme = ht_default_theme();
    theme.command.color_hex = json_strdup(theme.command.color_hex);
    theme.options.color_hex = json_strdup(theme.options.color_hex);
    theme.description.color_hex = json_strdup(theme.description.color_hex);

    const char *p = data;
    bool ok = true;
    if (!json_expect(&p, '{')) ok = false;
    while (ok) {
        json_skip_ws(&p);
        if (*p == '}') { p++; break; }
        char key[32];
        if (!json_parse_string(&p, key, sizeof(key))) { ok = false; break; }
        if (!json_expect(&p, ':')) { ok = false; break; }
        if (strcmp(key, "theme") == 0) {
            ht_theme_t parsed_theme;
            if (json_parse_theme(&p, &parsed_theme)) {
                free((void*)theme.command.color_hex);
                free((void*)theme.options.color_hex);
                free((void*)theme.description.color_hex);
                theme = parsed_theme;
            } else {
                ok = false;
                break;
            }
        } else {
            ok = false;
            break;
        }
        json_skip_ws(&p);
        if (*p == ',') { p++; continue; }
        else if (*p == '}') { p++; break; }
        else { ok = false; break; }
    }
    free(data);
    if (!ok) {
        free((void*)theme.command.color_hex);
        free((void*)theme.options.color_hex);
        free((void*)theme.description.color_hex);
        return NULL;
    }
    ht_config_file_t *cfg = malloc(sizeof(ht_config_file_t));
    if (!cfg) {
        free((void*)theme.command.color_hex);
        free((void*)theme.options.color_hex);
        free((void*)theme.description.color_hex);
        return NULL;
    }
    cfg->theme = theme;
    return cfg;
}

void ht_free_config(ht_config_file_t *cfg) {
    if (!cfg) return;
    free((void*)cfg->theme.command.color_hex);
    free((void*)cfg->theme.options.color_hex);
    free((void*)cfg->theme.description.color_hex);
    free(cfg);
}

void ht_apply_config(ht_opts_t *opts, const ht_config_file_t *cfg) {
    if (cfg) opts->theme = cfg->theme;
}

/* ------------------------------------------------------------------ */
/* Path targeting                                                      */
/* ------------------------------------------------------------------ */

const ht_command_t *ht_find_by_path(const ht_command_t *root,
                                    char **path, size_t path_count) {
    const ht_command_t *result = root;
    for (size_t i = 0; i < path_count; i++) {
        bool found = false;
        for (size_t j = 0; j < result->subcommand_count; j++) {
            if (strcmp(result->subcommands[j].name, path[i]) == 0) {
                result = &result->subcommands[j];
                found = true;
                break;
            }
        }
        if (!found) break;
    }
    return result;
}

void ht_run_for_tree(const ht_command_t *root, const ht_opts_t *opts,
                     char **path, size_t path_count) {
    const ht_command_t *selected = ht_find_by_path(root, path, path_count);
    if (opts->output == HT_JSON) {
        char *json = ht_render_json(selected, opts);
        printf("%s", json);
        free(json);
    } else {
        char *txt = ht_render_text(selected, opts);
        printf("%s\n\nUse `%s <COMMAND> --help` for full details on arguments and flags.\n",
               txt, root->name);
        free(txt);
    }
}
