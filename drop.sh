#!/usr/bin/env bash
DOTFILES="${DOTFILES:-$(dot-whereami)}"
. "$DOTFILES/utils/common.sh"

droppkg=

handle_positional_args() {
  droppkg=$1
  shift
}

parse_args "$@"
shift $#

[ -n "$droppkg" ] || die no package provided
info "Preparing to drop package $droppkg from $DOTMACHFILE"

# check if it's already in the file

if grep -qx "//$droppkg" "$DOTMACHFILE"; then
  warn "Package $droppkg already marked for drop"
elif ! grep -qx "$droppkg" "$DOTMACHFILE"; then
  error "Package $droppkg not found in $DOTMACHFILE. Nothing to drop."
  exit 1
else
  add_pkg_drop_marker "$droppkg"
fi

success "Package $droppkg marked for drop from $DOTMACHFILE. Running pull for package..."
"$DOTFILES/pull.sh" "//$droppkg"
