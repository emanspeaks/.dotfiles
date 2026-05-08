#!/usr/bin/env bash
DOTFILES=$(dot-whereami)
. "$DOTFILES/utils/common.sh"

machine=

handle_positional_args() {
  machine=$1
}

parse_args "$@"
machine=${machine:-$(get_machine_name)}
[ -n "$machine" ] || die "No machine name provided. Usage: $0 <machine-name>"

repomachfile="$DOTMACHDIR/$machine"
machpkgdir="$DOTPKGDIR/.machines/$machine"

success "Deploying dotfiles for machine $machine..."
mkdir -p "$(dirname $DOTMACHFILE)"
touch "$repomachfile"
[ -L "$DOTMACHFILE" ] || ln -sv "$repomachfile" "$DOTMACHFILE"
init_machine_base_pkgdir

if [ ! -s "$DOTMACHFILE" ]; then
  echo "base" >> "$DOTMACHFILE"
  echo "$MACHINEPKG" >> "$DOTMACHFILE"
fi
. "$DOTFILES/pull.sh"

success "Dotfiles repo initialized for machine $machine"
