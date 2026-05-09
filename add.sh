#!/usr/bin/env bash
DOTFILES=$(dot-whereami)
. "$DOTFILES/utils/common.sh"

newpkg=

handle_positional_args() {
  newpkg=$1
  shift
}

parse_args "$@"
shift $#

[ -n "$newpkg" ] || die no package provided
info "Preparing to add package $newpkg to $DOTMACHFILE"

# check if it's already in the file

if grep -qx "$newpkg" "$DOTMACHFILE"; then
  warn "Package $newpkg already added"
else
  echo $newpkg >> "$DOTMACHFILE"
  success "Package $newpkg added to $DOTMACHFILE.  Running pull for package..."
  "$DOTFILES/pull.sh" "$newpkg"
fi
