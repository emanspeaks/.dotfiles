#!/usr/bin/env bash
if command -v dot-whereami >/dev/null 2>&1; then
  DOTFILES="${DOTFILES:-$(dot-whereami)}"
else
  DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
fi
if [ -z "$DOTFILES" ]; then
  echo "Error: Unable to determine DOTFILES directory. Please set the DOTFILES environment variable." >&2
  exit 1
fi
. "$DOTFILES/utils/common.sh"

machine=

handle_positional_args() {
  machine=$1
  shift
}

parse_args "$@"
shift $#

machine=${machine:-$(get_machine_name)}
if [ -z "$machine" -a -n "$HOSTNAME" ]; then
  info "No machine name provided. Use current hostname '$HOSTNAME' as machine name?"
  read -p "(y/n) " yn
  case $yn in
    [Yy]* ) machine=$HOSTNAME;;
    * ) die "Machine name is required. Please provide a machine name as an argument or set the HOSTNAME environment variable.";;
  esac
fi
[ -n "$machine" ] || die "No machine name provided. Usage: $0 <machine-name>"

if [ -n "$MSYSTEM" ]; then
  # Test symlinks before we start a disaster
  [[ $MSYS == winsymlinks:nativestrict ]] && touch /tmp/dotlntest1 && ln -s /tmp/dotlntest1 /tmp/dotlntest2 && [ -L /tmp/dotlntest2 ] || {
    die "Symlinks are not working in this MSYS2 environment. Please ensure you have the latest MSYS2 installed and that Developer Mode is enabled."
  }
  rm -f /tmp/dotlntest1 /tmp/dotlntest2
  if ! command -v pacman >/dev/null 2>&1; then
    die "pacman not found. Please ensure you are running this script in an MSYS2 environment with pacman available."
  fi
  info "Running MSYS2 pacman system update"
  . "$DOTFILES/msys2-deploy.sh"
  echo
fi


repomachfile="$DOTMACHDIR/$machine"
machpkgdir="$DOTPKGDIR/.machines/$machine"

success "Deploying dotfiles for machine $machine..."
mkdir -p "$(dirname $DOTMACHFILE)"
touch "$repomachfile"
[ -L "$DOTMACHFILE" ] || ln -sv "$repomachfile" "$DOTMACHFILE"
init_machine_base_pkgdir

if [ ! -s "$DOTMACHFILE" ]; then
  echo "01-base" >> "$DOTMACHFILE"
  echo "$MACHINEPKG" >> "$DOTMACHFILE"
  if [ "$(which_os)" == "windows" ]; then
    echo "00-msys2" >> "$DOTMACHFILE"
    echo "04-windows" >> "$DOTMACHFILE"
  fi
  if [ -f "$SECRETSDIR/decrypt.sh" ]; then
    echo "02-secrets" >> "$DOTMACHFILE"
  fi

  # let's assume you want bash and neovim as starting defaults
  echo "bash" >> "$DOTMACHFILE"
  echo "nvim" >> "$DOTMACHFILE"
fi

read -p "Ready to pull, press Enter to continue..." DUMMY
. "$DOTFILES/pull.sh"

success "Dotfiles repo initialized for machine $machine"
