#!/usr/bin/env bash

# https://codeberg.org/ziglang/shell-completions/issues/20
completions_dir="${XDG_DATA_HOME:-"$HOME/.local/share"}/bash-completion/completions"
mkdir -p "$completions_dir"
zig_completion="$completions_dir/zig"
[ -f "$zig_completion" ] || curl -L --output="$zig_completion" "https://codeberg.org/ziglang/shell-completions/raw/branch/master/_zig.bash"
