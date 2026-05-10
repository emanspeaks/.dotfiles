#!/usr/bin/env bash
# this file is sourced by pull.sh, so any functions or variables there are available here

local -A winenv
get_win_env_assocref winenv
# cygbashpath=$(cygpath -wa "$(which bash)")
# echo "Detected Bash path: $cygbashpath"
bashpath="$USERPROFILE\.local\bin\opencode-bash.cmd"
# error $bashpath
win_env_ensure_value OPENCODE_GIT_BASH_PATH "$bashpath" winenv
win_env_ensure_value OPENCODE_ENABLE_EXA 1 winenv
