#!/bin/sh
if [ -n "$BASH_VERSION" ]; then
    # Bash-specific code
    SCRIPT_PATH="${BASH_SOURCE[0]}"
elif [ -n "$ZSH_VERSION" ]; then
    # Zsh-specific code
    SCRIPT_PATH="${(%):-%x}"
elif [ -n "$KSH_VERSION" ]; then
    # KornShell-specific code
    SCRIPT_PATH="${.sh.file}"
else
    # Fallback for generic POSIX shells (dash, etc.)
    SCRIPT_PATH="$0"
fi
echo $(cd "$(dirname "$(readlink -f "$SCRIPT_PATH")")" && pwd)
