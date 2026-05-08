#!/bin/sh
# if [ -n "$BASH_VERSION" ]; then
#     # Bash-specific code
#     SCRIPT_PATH="${BASH_SOURCE[0]}"
# elif [ -n "$ZSH_VERSION" ]; then
#     # Zsh-specific code
#     SCRIPT_PATH="${(%):-%x}"
# elif [ -n "$KSH_VERSION" ]; then
#     # KornShell-specific code
#     SCRIPT_PATH="${.sh.file}"
# else
#     # Fallback for generic POSIX shells (dash, etc.)
#     SCRIPT_PATH="$0"
# fi
# export DOTFILES=${DOTFILES:-$(cd "$(dirname "$(readlink -f "$SCRIPT_PATH")")" && pwd)}
# echo DOTFILES=$DOTFILES

export DOTFILES=$(dot-whereami)

export MSYS=winsymlinks:nativestrict
export DOTCFGDIR=~/.config/dotfiles
export DOTMACHFILE=$DOTCFGDIR/machine
export DOTMACHDIR="$DOTFILES/machines"
export DOTPKGDIR="$DOTFILES/pkgs"
export SECRETSDIR="$DOTFILES/secrets"
. "$SECRETSDIR/ansible-env.sh"
