#!/usr/bin/env bash
export DOTFILES=${DOTFILES:-$(dot-whereami)}
# echo $DOTFILES
. "$DOTFILES/exports.sh"
export DOTUTILS="$DOTFILES/utils"

. "$DOTUTILS/ansi.sh"
. "$DOTUTILS/helpers.sh"
