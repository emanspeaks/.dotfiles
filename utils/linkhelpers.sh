is_link_match() {
  local src=$(readlink -f "$1")
  local dest="$2"
  local raise=$3

  debug_or_die() {
    local bashsrc="$1"
    local linenum="$2"
    shift 2
    [ $raise -eq 1 ] && die "$@" || debug "$bashsrc" "$linenum" "$@"
  }

  if [ ! -e "$dest" ]; then
    debug "$BASH_SOURCE" "$LINENO" "Target $dest does not exist"
    return 1
  fi
  if [ -L "$dest" ]; then
    local linktgt=$(readlink -f "$dest")
    if [ "$linktgt" == "$src" ]; then
      debug "$BASH_SOURCE" "$LINENO" "${INVERT}Link $dest already exists and is correct${NOINVERT}"
      return 0
    fi
    debug_or_die "$BASH_SOURCE" "$LINENO" "Existing link $dest -> $linktgt does not match expected target $src"
    return 2
  fi
  debug_or_die "$BASH_SOURCE" "$LINENO" "Target $dest exists but is not a link"
  return 3
}

safe_link() {
  local src="$1"  # true file or directory we want to link to
  local dest="$2"  # destination of the link we want to create
  is_link_match "$src" "$dest" 1 || ln -sv "$src" "$dest" || die "Failed to link $dest to $src"
}

replace_dir_with_link() {
  local src="$1"  # true dir we want to link to
  local dest="$2"  # dir we want to replace with a link to src
  local skiplevel="$3"  # if > 0, we will not proceed
  debug "$BASH_SOURCE" "$LINENO" "replace_dir_with_link: src=$src dest=$dest"
  if [ "$skiplevel" -gt 0 ]; then
    debug "$BASH_SOURCE" "$LINENO" "skiplevel=$skiplevel, skipping link replacement of $dest"
    return 1
  fi

  # check if it's in the noln for pkg before we proceed
  local srcchk="$(strip_trailing_slash "$src")/"
  local noln=()
  filter_noln_for_path_nolnref "$srcchk" noln
  for nolnpath in "${noln[@]}"; do
    if [[ "$srcchk" == "$nolnpath/" ]]; then
      debug "$BASH_SOURCE" "$LINENO" "${INVERT}Path $srcchk is in noln, skipping link replacement of $dest${NOINVERT}"
      return 1
    fi
  done

  # if we got here, we can proceed with the replacement
  debug "$BASH_SOURCE" "$LINENO" rm -rfv "$dest"
  breakpoint "$BASH_SOURCE" "$LINENO"
  rm -rfv "$dest" || die "Failed to remove existing directory $dest"
  # we will let the pull rebuild the link for us, there may be more work to do.
  pull_src_dest_skiplevel_noln "$src" "$dest" 0 "${noln[@]}"
}

replace_link_with_dir() {
  local src="$1"
  local dest="$2"
  local linktgt="$3"
  debug "$BASH_SOURCE" "$LINENO" "replace_link_with_dir: src=$src dest=$dest linktgt=$linktgt"
  # example:
  # src: /home/user/.dotfiles/pkgs/foo/home/.config
  # dest: /home/user/.config
  # linktgt: /home/user/.dotfiles/pkgs/bar/home/.config
  debug "$BASH_SOURCE" "$LINENO" rm "$dest"
  breakpoint "$BASH_SOURCE" "$LINENO"
  rm "$dest" || die "Failed to remove existing link $dest"
  debug "$BASH_SOURCE" "$LINENO" mkdir -p "$dest"
  mkdir -p "$dest" || die "Failed to create directory $dest"

  # need to partially re-pull the other pkg
  local noln=()
  filter_noln_for_path_nolnref "$linktgt" noln
  # if we got here, we previously had a link at this level already,
  # so we can safely assume skiplevel must be at least 0
  pull_src_dest_skiplevel_noln "$linktgt" "$dest" 0 "${noln[@]}"

  # we will let the caller resume where they left off at this point and
  # will not link the directory for them, there may be more work to do.
}
