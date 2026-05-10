#!/usr/bin/env bash
# this file is sourced by pull.sh, so any functions or variables there are available here

local -A winenv
get_win_env_assocref winenv
# cygbashpath=$(cygpath -wa "$(which bash)")
# echo "Detected Bash path: $cygbashpath"
cygbashpath="$USERPROFILE\\.local\\bin\\opencode-bash.cmd"
[[ "${winenv[OPENCODE_GIT_BASH_PATH]}" == "$cygbashpath" ]] || setx OPENCODE_GIT_BASH_PATH "$cygbashpath"
[[ "${winenv[OPENCODE_ENABLE_EXA]}" == "1" ]] || setx OPENCODE_ENABLE_EXA 1
