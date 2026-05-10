#!/usr/bin/env bash
DOTFILES="${DOTFILES:-$(dot-whereami)}"
. "$DOTFILES/utils/common.sh"

singlepkg=

handle_positional_args() {
  singlepkg=$1
  shift
}

parse_args "$@"
shift $#

success "Pushing dotfiles packages..."
cd "$DOTFILES"
git pull || warn "Failed to pull latest changes from git. Continuing with local copy of dotfiles."
readarray -t pkgs < <(cat "$DOTMACHFILE" | sort -u)
if [ -n "$singlepkg" ]; then
  if [[ " ${pkgs[*]} " == *" $singlepkg "* ]]; then
    pkgs=("$singlepkg")
  else
    die "Package $singlepkg not found in $DOTMACHFILE"
  fi
fi

update=0
failed=0
for pkg in "${pkgs[@]}"; do
  die NOT YET IMPLEMENTED, DO NOT USE
  if push_pkg "$pkg"; then
    (( update++ ));
  else
    (( failed++ ))
    warn "Failed to push package $pkg. Continuing with next package."
  fi
done

if [ $update -gt 0 ]; then
  if [ $failed -gt 0 ]; then
    warn "$failed packages failed to update"
  fi
  success "$update Dotfiles packages updated"
elif [ $failed -gt 0 ]; then
  error "All packages failed to update"
else
  warn "No packages were updated"
fi
exit $failed
