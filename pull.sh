#!/usr/bin/env bash
DOTFILES=$(dot-whereami)
. "$DOTFILES/utils/common.sh"

inputpkgs=

handle_positional_args() {
  inputpkgs=("$@")
  shift $#
}

parse_args "$@"
shift $#

success "Pulling dotfiles packages..."
cd "$DOTFILES"
git pull || warn "Failed to pull latest changes from git. Continuing with local copy of dotfiles."

filepkgs=$(parse_pattern_file "$DOTMACHFILE")
if [ -n "$inputpkgs" ]; then
  pkgs=()
  for pkg in "${inputpkgs[@]}"; do
    if grep -qx "$pkg" <<< "$filepkgs"; then
      pkgs+=("$pkg")
    else
      die "Package $pkg not found in $DOTMACHFILE"
    fi
  done
else
  readarray -t pkgs < <(echo "$filepkgs")
fi

update=0
failed=0
dropped=0
for pkg in "${pkgs[@]}"; do
  drop=0
  if [[ $pkg == //* ]]; then
    drop=1
    pkg="${pkg:2}"
  fi
  [[ $pkg == "$MACHINEPKG" ]] && [[ $drop -eq 0 ]] && init_machine_base_pkgdir
  if [ -d "$(pkg_name_to_pkgdir "$pkg")" ]; then
    if [ $drop -eq 1 ]; then
      if drop_pkg "$pkg"; then
        comment_pkg_drop_marker "$pkg"
        (( dropped++ ));
      else
        (( failed++ ))
        warn "Failed to drop package $pkg. Continuing with next package."
      fi
    elif pull_pkg "$pkg" 0; then
      (( update++ ));
    else
      (( failed++ ))
      warn "Failed to pull package $pkg. Continuing with next package."
    fi
  else
    warn "Package $pkg does not exist. Skipping pull for this package."
  fi
done

if [ $update -gt 0 ]; then
  if [ $failed -gt 0 ]; then
    warn "$failed packages failed to update"
  fi
  success "$update Dotfiles packages updated"
  if [ $dropped -gt 0 ]; then
    success "$dropped Dotfiles packages dropped"
  fi
elif [ $dropped -gt 0 ]; then
  success "All specified packages ($dropped) dropped"
elif [ $failed -gt 0 ]; then
  error "All specified packages ($failed) failed to update"
else
  warn "No packages were updated"
fi
exit $failed
