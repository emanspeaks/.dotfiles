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
  rm "$dest" || die "Failed to remove existing link $dest"
  debug "$BASH_SOURCE" "$LINENO" mkdir -p "$dest"
  mkdir -p "$dest" || die "Failed to create directory $dest"

  # need to partially re-pull the other pkg
  local pkgdir=$(extract_pkgdir_from_path "$linktgt")  # /home/user/.dotfiles/pkgs/bar
  local nolnrelpath=$(strip_pkgdir_from_path "$linktgt")  # home/.config
  debug "$BASH_SOURCE" "$LINENO" pkgdir="$pkgdir" nolnrelpath="$nolnrelpath"
  local noln=()
  local home_noln=()
  local root_noln=()
  local userprofile_noln=()
  noln_for_pkgdir_home_root_userprofile "$pkgdir" home_noln root_noln userprofile_noln
  case "$linktgt" in
    "$pkgdir/home/"*)
      filter_noln noln "${nolnrelpath#home/}" "${home_noln[@]}"
      ;;
    "$pkgdir/root/"*)
      filter_noln noln "${nolnrelpath#root/}" "${root_noln[@]}"
      ;;
    "$pkgdir/userprofile/"*)
      filter_noln noln "${nolnrelpath#userprofile/}" "${userprofile_noln[@]}"
      ;;
    *)
      die "Link target $linktgt is not in home, root, or userprofile"
      ;;
  esac
  # if we got here, we previously had a link at this level already,
  # so we can safely assume skiplevel must be at least 0
  warn
  pull_src_dest_skiplevel_noln "$linktgt" "$dest" 0 "${noln[@]}"

  # we will let the caller resume where they left off at this point and
  # will not link the directory for them, there may be more work to do.
}
