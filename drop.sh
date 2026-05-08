#!/usr/bin/env bash
DOTFILES=$(dot-whereami)
. "$DOTFILES/utils/common.sh"

parse_args "$@"

droppkg=$1
[ -n "$droppkg" ] || die no package provided
info "Preparing to drop package $droppkg from $DOTMACHFILE"

# check if it's already in the file

if grep -qx "#$droppkg" "$DOTMACHFILE"; then
  warn "Package $droppkg already dropped"
else
  die NOT YET IMPLEMENTED, DO NOT USE

  echo "#$droppkg" >> "$DOTMACHFILE"
  success "Package $droppkg dropped from $DOTMACHFILE. Running pull for package..."
  "$DOTFILES/pull.sh" "#$droppkg"
fi
