is_link_match() {
  local src=$(readlink -f "$1")
  local dest="$2"
  local raise=$3

  debug_or_die() {
    local bashsrc="$1"
    local linenum="$2"
    shift 2
    [[ "$raise" -eq 1 ]] && die "$@" || debug "$bashsrc" "$linenum" "$@"
  }

  if [ -L "$dest" ]; then
    local linktgt=$(readlink -f "$dest")
    if [ "$linktgt" == "$src" ]; then
      debug "$BASH_SOURCE" "$LINENO" "${INVERT}Link $dest already exists and is correct${NOINVERT}"
      return 0
    fi
    debug_or_die "$BASH_SOURCE" "$LINENO" "Existing link $dest -> $linktgt does not match expected target $src"
    return 2
  elif [ -e "$dest" ]; then
    debug_or_die "$BASH_SOURCE" "$LINENO" "Target $dest exists but is not a link"
    return 3
  else
    # maybe it's a Windows-ism or MSYS2-ism, but symlinks that "exist" do not pass the -e test,
    # so if we checked -e first (which this code originally did), we would think the target doesn't exist,
    # and then be surprised when we try to create the link and it fails because the target already exists.
    # By checking -L first, we can detect this case and report it more accurately.
    #
    # I put this note here because it's possible something similar could happen in the future if we have some
    # sort of weird thing like a socket or device or something that isn't a "file" but that exists and yet
    # doesn't pass the -e test. So this may be a false alarm saying it definitely doesn't exist here.
    # I'll be grateful in the future if I am debugging some weird edge case and find myself back here again wondering
    # why it thinks a file doesn't "exist" that clearly does.
    debug "$BASH_SOURCE" "$LINENO" "Target $dest does not exist"
    return 1
  fi

}

safe_link() {
  local src="$1"  # true file or directory we want to link to
  local dest="$2"  # destination of the link we want to create
  is_link_match "$src" "$dest" 1 || ln -sv "$src" "$dest" || die "Failed to link $dest to $src"
}

try_set_link() {
  local src="$1"  # true file or directory we want to link to
  local dest="$2"  # destination of the link we want to create
  local linktgt
  is_link_match "$src" "$dest"
  case $? in
    0)
      # is_link_match already logged, we're done here
      return 0
      ;;
    1)
      # target does not exist, we can link it
      safe_link "$src" "$dest"
      return 0
      ;;
    2)
      # it's a link, but to the wrong target, we can replace it if it's one of ours
      linktgt=$(readlink "$dest")  # no -f, do not resolve link, use the nominal path
      if [[ "$linktgt" == "$DOTPKGDIR/"* ]]; then
        error "Existing link $dest -> $linktgt in another dotfiles pkg."
        warn "Would you like to replace it with the new link (-> $src)?"
        read -p "(y/n) " yn
        case $yn in
          [Yy]* )
            debug "$BASH_SOURCE" "$LINENO" "${INVERT}Replacing link $dest with correct link to $src${NOINVERT}"
            rm "$dest" || die "Failed to remove existing link $dest"
            safe_link "$src" "$dest"
            return 1
            ;;
          *)
            die "Cannot proceed with existing incorrect links.  Please resolve the conflict at $dest manually and try again."
        esac
      else
        die "Existing link $dest -> $linktgt is outside dotfiles.  Cannot proceed with conflicting link."
      fi
      ;;
    3)
      die "Target exists but is not a link (but we shouldn't be here since we already checked?)"
      ;;
    *)
      die "Unexpected return value from is_link_match"
      ;;
  esac
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
