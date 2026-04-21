#!/usr/bin/env bash
# run-all-examples.sh — Run all HelpTree examples across all supported languages.
# Usage: ./run-all-examples.sh [language]
#   With no argument: runs examples for all languages
#   With argument:    runs examples for the specified language only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}"

# Colors for output (using $'...' C-style strings for actual escape bytes)
BOLD=$'\033[1m'
RESET=$'\033[0m'
GREEN=$'\033[32m'
RED=$'\033[31m'
YELLOW=$'\033[33m'
CYAN=$'\033[36m'

header() {
    echo ""
    echo "${BOLD}${CYAN}══════════════════════════════════════════════════════════════════${RESET}"
    echo "${BOLD}${CYAN}  $1${RESET}"
    echo "${BOLD}${CYAN}══════════════════════════════════════════════════════════════════${RESET}"
}

subheader() {
    echo ""
    echo "${BOLD}▸ $1${RESET}"
}

run_cmd() {
    local lang="$1"
    local label="$2"
    shift 2
    echo "    ${YELLOW}\$${RESET} $*"
    if "$@"; then
        echo "    ${GREEN}✓ $label passed${RESET}"
    else
        echo "    ${RED}✗ $label failed (exit $?)${RESET}"
        return 1
    fi
}

# Check if a command exists
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# ── Rust ──────────────────────────────────────────────────────────
run_rust() {
    header "Rust (clap)"
    cd "${REPO_ROOT}/rust"

    subheader "basic — full tree + JSON + path targeting"
    run_cmd rust "basic text" cargo run -p help-tree --example basic -- --help-tree
    run_cmd rust "basic depth limit" cargo run -p help-tree --example basic -- --help-tree -L 1
    run_cmd rust "basic json" cargo run -p help-tree --example basic -- --help-tree --tree-output json
    run_cmd rust "basic path" cargo run -p help-tree --example basic -- project --help-tree

    subheader "deep — 3-level nesting"
    run_cmd rust "deep text" cargo run -p help-tree --example deep -- --help-tree
    run_cmd rust "deep depth 1" cargo run -p help-tree --example deep -- --help-tree -L 1
    run_cmd rust "deep depth 2" cargo run -p help-tree --example deep -- --help-tree -L 2
    run_cmd rust "deep path" cargo run -p help-tree --example deep -- server config --help-tree

    subheader "hidden — hidden commands/flags"
    run_cmd rust "hidden default" cargo run -p help-tree --example hidden -- --help-tree
    run_cmd rust "hidden all" cargo run -p help-tree --example hidden -- --help-tree -a
}

# ── Python ────────────────────────────────────────────────────────
run_python() {
    header "Python (argparse)"
    cd "${REPO_ROOT}/python"

    subheader "basic"
    run_cmd python "basic text" python examples/basic.py --help-tree
    run_cmd python "basic depth" python examples/basic.py --help-tree -L 1
    run_cmd python "basic json" python examples/basic.py --help-tree --tree-output json
    run_cmd python "basic path" python examples/basic.py project --help-tree

    subheader "deep"
    run_cmd python "deep text" python examples/deep.py --help-tree
    run_cmd python "deep depth 1" python examples/deep.py --help-tree -L 1
    run_cmd python "deep depth 2" python examples/deep.py --help-tree -L 2
    run_cmd python "deep path" python examples/deep.py server config --help-tree

    subheader "hidden"
    run_cmd python "hidden default" python examples/hidden.py --help-tree
    run_cmd python "hidden all" python examples/hidden.py --help-tree -a
}

# ── TypeScript ────────────────────────────────────────────────────
run_typescript() {
    header "TypeScript (commander)"
    cd "${REPO_ROOT}/typescript"

    subheader "basic"
    run_cmd ts "basic text" npx ts-node examples/basic.ts --help-tree
    run_cmd ts "basic depth" npx ts-node examples/basic.ts --help-tree -L 1
    run_cmd ts "basic json" npx ts-node examples/basic.ts --help-tree --tree-output json
    run_cmd ts "basic path" npx ts-node examples/basic.ts project --help-tree

    subheader "deep"
    run_cmd ts "deep text" npx ts-node examples/deep.ts --help-tree
    run_cmd ts "deep depth 1" npx ts-node examples/deep.ts --help-tree -L 1
    run_cmd ts "deep depth 2" npx ts-node examples/deep.ts --help-tree -L 2
    run_cmd ts "deep path" npx ts-node examples/deep.ts server config --help-tree

    subheader "hidden"
    run_cmd ts "hidden default" npx ts-node examples/hidden.ts --help-tree
    run_cmd ts "hidden all" npx ts-node examples/hidden.ts --help-tree -a
}

# ── Go ────────────────────────────────────────────────────────────
run_go() {
    header "Go (cobra)"
    cd "${REPO_ROOT}/go"

    subheader "basic"
    run_cmd go "basic text" bash -c "cd examples/basic && go run . --help-tree"
    run_cmd go "basic depth" bash -c "cd examples/basic && go run . --help-tree -L 1"
    run_cmd go "basic json" bash -c "cd examples/basic && go run . --help-tree --tree-output json"
    run_cmd go "basic path" bash -c "cd examples/basic && go run . project --help-tree"

    subheader "deep"
    run_cmd go "deep text" bash -c "cd examples/deep && go run . --help-tree"
    run_cmd go "deep depth 1" bash -c "cd examples/deep && go run . --help-tree -L 1"
    run_cmd go "deep depth 2" bash -c "cd examples/deep && go run . --help-tree -L 2"
    run_cmd go "deep path" bash -c "cd examples/deep && go run . server config --help-tree"

    subheader "hidden"
    run_cmd go "hidden default" bash -c "cd examples/hidden && go run . --help-tree"
    run_cmd go "hidden all" bash -c "cd examples/hidden && go run . --help-tree -a"
}

# ── C# ────────────────────────────────────────────────────────────
run_csharp() {
    header "C# (System.CommandLine)"
    cd "${REPO_ROOT}/csharp"

    subheader "basic"
    run_cmd csharp "basic text" bash -c "cd examples/basic && MSBUILDTERMINALLOGGER=off dotnet run -- --help-tree"
    run_cmd csharp "basic depth" bash -c "cd examples/basic && MSBUILDTERMINALLOGGER=off dotnet run -- --help-tree -L 1"
    run_cmd csharp "basic json" bash -c "cd examples/basic && MSBUILDTERMINALLOGGER=off dotnet run -- --help-tree --tree-output json"
    run_cmd csharp "basic path" bash -c "cd examples/basic && MSBUILDTERMINALLOGGER=off dotnet run -- project --help-tree"

    subheader "deep"
    run_cmd csharp "deep text" bash -c "cd examples/deep && MSBUILDTERMINALLOGGER=off dotnet run -- --help-tree"
    run_cmd csharp "deep depth 1" bash -c "cd examples/deep && MSBUILDTERMINALLOGGER=off dotnet run -- --help-tree -L 1"
    run_cmd csharp "deep depth 2" bash -c "cd examples/deep && MSBUILDTERMINALLOGGER=off dotnet run -- --help-tree -L 2"
    run_cmd csharp "deep path" bash -c "cd examples/deep && MSBUILDTERMINALLOGGER=off dotnet run -- server config --help-tree"

    subheader "hidden"
    run_cmd csharp "hidden default" bash -c "cd examples/hidden && MSBUILDTERMINALLOGGER=off dotnet run -- --help-tree"
    run_cmd csharp "hidden all" bash -c "cd examples/hidden && MSBUILDTERMINALLOGGER=off dotnet run -- --help-tree -a"
}

# ── Swift ─────────────────────────────────────────────────────────
run_swift() {
    header "Swift (ArgumentParser)"
    cd "${REPO_ROOT}/swift"

    subheader "basic"
    run_cmd swift "basic text" swift run Basic --help-tree
    run_cmd swift "basic depth" swift run Basic --help-tree -L 1
    run_cmd swift "basic json" swift run Basic --help-tree --tree-output json
    run_cmd swift "basic path" swift run Basic project --help-tree

    subheader "deep"
    run_cmd swift "deep text" swift run Deep --help-tree
    run_cmd swift "deep depth 1" swift run Deep --help-tree -L 1
    run_cmd swift "deep depth 2" swift run Deep --help-tree -L 2
    run_cmd swift "deep path" swift run Deep server config --help-tree

    subheader "hidden"
    run_cmd swift "hidden default" swift run Hidden --help-tree
    run_cmd swift "hidden all" swift run Hidden --help-tree -a
}

# ── Nim ───────────────────────────────────────────────────────────
run_nim() {
    header "Nim (cligen)"
    cd "${REPO_ROOT}/nim"

    subheader "basic"
    run_cmd nim "basic text" nim c -r --path:src examples/basic.nim --help-tree
    run_cmd nim "basic depth" nim c -r --path:src examples/basic.nim --help-tree -L 1
    run_cmd nim "basic json" nim c -r --path:src examples/basic.nim --help-tree --tree-output json
    run_cmd nim "basic path" nim c -r --path:src examples/basic.nim project --help-tree

    subheader "deep"
    run_cmd nim "deep text" nim c -r --path:src examples/deep.nim --help-tree
    run_cmd nim "deep depth 1" nim c -r --path:src examples/deep.nim --help-tree -L 1
    run_cmd nim "deep depth 2" nim c -r --path:src examples/deep.nim --help-tree -L 2
    run_cmd nim "deep path" nim c -r --path:src examples/deep.nim server config --help-tree

    subheader "hidden"
    run_cmd nim "hidden default" nim c -r --path:src examples/hidden.nim --help-tree
    run_cmd nim "hidden all" nim c -r --path:src examples/hidden.nim --help-tree -a
}

# ── Crystal ───────────────────────────────────────────────────────
run_crystal() {
    header "Crystal (OptionParser)"
    cd "${REPO_ROOT}/crystal"

    subheader "basic"
    run_cmd crystal "basic text" crystal run examples/basic.cr -- --help-tree
    run_cmd crystal "basic depth" crystal run examples/basic.cr -- --help-tree -L 1
    run_cmd crystal "basic json" crystal run examples/basic.cr -- --help-tree --tree-output json
    run_cmd crystal "basic path" crystal run examples/basic.cr -- project --help-tree

    subheader "deep"
    run_cmd crystal "deep text" crystal run examples/deep.cr -- --help-tree
    run_cmd crystal "deep depth 1" crystal run examples/deep.cr -- --help-tree -L 1
    run_cmd crystal "deep depth 2" crystal run examples/deep.cr -- --help-tree -L 2
    run_cmd crystal "deep path" crystal run examples/deep.cr -- server config --help-tree

    subheader "hidden"
    run_cmd crystal "hidden default" crystal run examples/hidden.cr -- --help-tree
    run_cmd crystal "hidden all" crystal run examples/hidden.cr -- --help-tree -a
}

# ── Ruby ──────────────────────────────────────────────────────────
run_ruby() {
    header "Ruby (Thor)"
    cd "${REPO_ROOT}/ruby"

    subheader "basic"
    run_cmd ruby "basic text" ruby examples/basic.rb --help-tree
    run_cmd ruby "basic depth" ruby examples/basic.rb --help-tree -L 1
    run_cmd ruby "basic json" ruby examples/basic.rb --help-tree --tree-output json
    run_cmd ruby "basic path" ruby examples/basic.rb project --help-tree

    subheader "deep"
    run_cmd ruby "deep text" ruby examples/deep.rb --help-tree
    run_cmd ruby "deep depth 1" ruby examples/deep.rb --help-tree -L 1
    run_cmd ruby "deep depth 2" ruby examples/deep.rb --help-tree -L 2
    run_cmd ruby "deep path" ruby examples/deep.rb server config --help-tree

    subheader "hidden"
    run_cmd ruby "hidden default" ruby examples/hidden.rb --help-tree
    run_cmd ruby "hidden all" ruby examples/hidden.rb --help-tree -a
}

# ── Zig ───────────────────────────────────────────────────────────
run_zig() {
    header "Zig"
    cd "${REPO_ROOT}/zig"

    subheader "basic"
    run_cmd zig "basic text" zig build run-basic -- --help-tree
    run_cmd zig "basic depth" zig build run-basic -- --help-tree -L 1
    run_cmd zig "basic json" zig build run-basic -- --help-tree --tree-output json
    run_cmd zig "basic path" zig build run-basic -- project --help-tree

    subheader "deep"
    run_cmd zig "deep text" zig build run-deep -- --help-tree
    run_cmd zig "deep depth 1" zig build run-deep -- --help-tree -L 1
    run_cmd zig "deep depth 2" zig build run-deep -- --help-tree -L 2
    run_cmd zig "deep path" zig build run-deep -- server config --help-tree

    subheader "hidden"
    run_cmd zig "hidden default" zig build run-hidden -- --help-tree
    run_cmd zig "hidden all" zig build run-hidden -- --help-tree -a
}

# ── Haskell ───────────────────────────────────────────────────────
run_haskell() {
    header "Haskell (optparse-applicative)"
    cd "${REPO_ROOT}/haskell"
    export PATH="$HOME/.ghcup/bin:$PATH"

    subheader "basic"
    run_cmd haskell "basic text" stack run basic -- --help-tree
    run_cmd haskell "basic depth" stack run basic -- --help-tree -L 1
    run_cmd haskell "basic json" stack run basic -- --help-tree --tree-output json
    run_cmd haskell "basic path" stack run basic -- project --help-tree

    subheader "deep"
    run_cmd haskell "deep text" stack run deep -- --help-tree
    run_cmd haskell "deep depth 1" stack run deep -- --help-tree -L 1
    run_cmd haskell "deep depth 2" stack run deep -- --help-tree -L 2
    run_cmd haskell "deep path" stack run deep -- server config --help-tree

    subheader "hidden"
    run_cmd haskell "hidden default" stack run hidden -- --help-tree
    run_cmd haskell "hidden all" stack run hidden -- --help-tree -a
}

# ── C ─────────────────────────────────────────────────────────────
run_c() {
    header "C (manual)"
    cd "${REPO_ROOT}/c"
    make basic deep hidden

    subheader "basic"
    run_cmd c "basic text" ./examples/basic --help-tree
    run_cmd c "basic depth" ./examples/basic --help-tree -L 1
    run_cmd c "basic json" ./examples/basic --help-tree --tree-output json
    run_cmd c "basic path" ./examples/basic project --help-tree

    subheader "deep"
    run_cmd c "deep text" ./examples/deep --help-tree
    run_cmd c "deep depth 1" ./examples/deep --help-tree -L 1
    run_cmd c "deep depth 2" ./examples/deep --help-tree -L 2
    run_cmd c "deep path" ./examples/deep server config --help-tree

    subheader "hidden"
    run_cmd c "hidden default" ./examples/hidden --help-tree
    run_cmd c "hidden all" ./examples/hidden --help-tree -a
}

# ── C++ ───────────────────────────────────────────────────────────
run_cpp() {
    header "C++ (CLI11)"
    cd "${REPO_ROOT}/cpp"
    cmake -B build >/dev/null 2>&1 && cmake --build build >/dev/null 2>&1

    subheader "basic"
    run_cmd cpp "basic text" ./build/examples/basic --help-tree
    run_cmd cpp "basic depth" ./build/examples/basic --help-tree -L 1
    run_cmd cpp "basic json" ./build/examples/basic --help-tree --tree-output json
    run_cmd cpp "basic path" ./build/examples/basic project --help-tree

    subheader "deep"
    run_cmd cpp "deep text" ./build/examples/deep --help-tree
    run_cmd cpp "deep depth 1" ./build/examples/deep --help-tree -L 1
    run_cmd cpp "deep depth 2" ./build/examples/deep --help-tree -L 2
    run_cmd cpp "deep path" ./build/examples/deep server config --help-tree

    subheader "hidden"
    run_cmd cpp "hidden default" ./build/examples/hidden --help-tree
    run_cmd cpp "hidden all" ./build/examples/hidden --help-tree -a
}

# ── Java ──────────────────────────────────────────────────────────
run_java() {
    header "Java (picocli)"
    cd "${REPO_ROOT}/java"
    gradle build >/dev/null 2>&1

    subheader "basic"
    run_cmd java "basic text" gradle run -PmainClass=helptree.examples.Basic --args="--help-tree"
    run_cmd java "basic depth" gradle run -PmainClass=helptree.examples.Basic --args="--help-tree -L 1"
    run_cmd java "basic json" gradle run -PmainClass=helptree.examples.Basic --args="--help-tree --tree-output json"
    run_cmd java "basic path" gradle run -PmainClass=helptree.examples.Basic --args="project --help-tree"

    subheader "deep"
    run_cmd java "deep text" gradle run -PmainClass=helptree.examples.Deep --args="--help-tree"
    run_cmd java "deep depth 1" gradle run -PmainClass=helptree.examples.Deep --args="--help-tree -L 1"
    run_cmd java "deep depth 2" gradle run -PmainClass=helptree.examples.Deep --args="--help-tree -L 2"
    run_cmd java "deep path" gradle run -PmainClass=helptree.examples.Deep --args="server config --help-tree"

    subheader "hidden"
    run_cmd java "hidden default" gradle run -PmainClass=helptree.examples.Hidden --args="--help-tree"
    run_cmd java "hidden all" gradle run -PmainClass=helptree.examples.Hidden --args="--help-tree -a"
}

# ── Julia ─────────────────────────────────────────────────────────
run_julia() {
    header "Julia (ArgParse)"
    cd "${REPO_ROOT}/julia"

    subheader "basic"
    run_cmd julia "basic text" julia examples/basic.jl --help-tree
    run_cmd julia "basic depth" julia examples/basic.jl --help-tree -L 1
    run_cmd julia "basic json" julia examples/basic.jl --help-tree --tree-output json
    run_cmd julia "basic path" julia examples/basic.jl project --help-tree

    subheader "deep"
    run_cmd julia "deep text" julia examples/deep.jl --help-tree
    run_cmd julia "deep depth 1" julia examples/deep.jl --help-tree -L 1
    run_cmd julia "deep depth 2" julia examples/deep.jl --help-tree -L 2
    run_cmd julia "deep path" julia examples/deep.jl server config --help-tree

    subheader "hidden"
    run_cmd julia "hidden default" julia examples/hidden.jl --help-tree
    run_cmd julia "hidden all" julia examples/hidden.jl --help-tree -a
}

# ── Lua ───────────────────────────────────────────────────────────
run_lua() {
    header "Lua (manual)"
    cd "${REPO_ROOT}/lua"

    subheader "basic"
    run_cmd lua "basic text" lua examples/basic.lua --help-tree
    run_cmd lua "basic depth" lua examples/basic.lua --help-tree -L 1
    run_cmd lua "basic json" lua examples/basic.lua --help-tree --tree-output json
    run_cmd lua "basic path" lua examples/basic.lua project --help-tree

    subheader "deep"
    run_cmd lua "deep text" lua examples/deep.lua --help-tree
    run_cmd lua "deep depth 1" lua examples/deep.lua --help-tree -L 1
    run_cmd lua "deep depth 2" lua examples/deep.lua --help-tree -L 2
    run_cmd lua "deep path" lua examples/deep.lua server config --help-tree

    subheader "hidden"
    run_cmd lua "hidden default" lua examples/hidden.lua --help-tree
    run_cmd lua "hidden all" lua examples/hidden.lua --help-tree -a
}

# ── OCaml ─────────────────────────────────────────────────────────
run_ocaml() {
    header "OCaml (manual)"
    cd "${REPO_ROOT}/ocaml"
    make basic deep hidden

    subheader "basic"
    run_cmd ocaml "basic text" ./examples/basic --help-tree
    run_cmd ocaml "basic depth" ./examples/basic --help-tree -L 1
    run_cmd ocaml "basic json" ./examples/basic --help-tree --tree-output json
    run_cmd ocaml "basic path" ./examples/basic project --help-tree

    subheader "deep"
    run_cmd ocaml "deep text" ./examples/deep --help-tree
    run_cmd ocaml "deep depth 1" ./examples/deep --help-tree -L 1
    run_cmd ocaml "deep depth 2" ./examples/deep --help-tree -L 2
    run_cmd ocaml "deep path" ./examples/deep server config --help-tree

    subheader "hidden"
    run_cmd ocaml "hidden default" ./examples/hidden --help-tree
    run_cmd ocaml "hidden all" ./examples/hidden --help-tree -a
}

# ── Run all ───────────────────────────────────────────────────────
run_all() {
    local failed=0
    for lang in rust python typescript go csharp swift nim crystal ruby zig haskell c cpp java julia lua ocaml; do
        if ! "run_${lang}" 2>&1; then
            failed=$((failed + 1))
            echo ""
            echo "${RED}${BOLD}  ⚠ ${lang} had failures — continuing...${RESET}"
        fi
    done

    echo ""
    echo "${BOLD}${CYAN}══════════════════════════════════════════════════════════════════${RESET}"
    if [[ $failed -eq 0 ]]; then
        echo "${BOLD}${GREEN}  ✓ All examples passed across all languages${RESET}"
    else
        echo "${BOLD}${RED}  ✗ $failed language(s) had failures${RESET}"
    fi
    echo "${BOLD}${CYAN}══════════════════════════════════════════════════════════════════${RESET}"
    return $failed
}

# Main entry
if [[ $# -eq 0 ]]; then
    run_all
else
    LANG="$1"
    case "$LANG" in
        rust|python|typescript|go|csharp|swift|nim|crystal|ruby|zig|haskell|c|cpp|java|julia|lua|ocaml)
            "run_${LANG}" 2>&1
            ;;
        *)
            echo "Unknown language: $LANG"
            echo "Supported: rust python typescript go csharp swift nim crystal ruby zig haskell c cpp java julia lua ocaml"
            exit 1
            ;;
    esac
fi
