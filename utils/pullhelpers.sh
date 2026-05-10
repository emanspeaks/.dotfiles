pull_src_dest_skiplevel_noln() {
  local src="$1"
  local dest="$2"
  local skiplevel="$3"
  local noln=($(echo "${@:4}" | sort -u))  # remove duplicates just in case
  debug "$BASH_SOURCE" "$LINENO" "pull_src_dest_skiplevel_noln src=$src dest=$dest skiplevel=$skiplevel noln=(${noln[@]})"
  breakpoint "$BASH_SOURCE" "$LINENO"

  # get the first path part of each src path
  local srclen=$(( $(echo "$src" | wc -m) + 1 ))  # add 1 for trailing slash
  readarray -t first < <(find -L "$src" -type f -o -type l | cut -c $srclen- | cut -d/ -f1 | sort -u)
  for p in "${first[@]}"; do
    [[ -z "$p" ]] && die "Unexpected empty path part for src=$src dest=$dest first=(${first[@]})"
    debug "$BASH_SOURCE" "$LINENO" src=$src dest=$dest p=$p
    breakpoint "$BASH_SOURCE" "$LINENO"
    # check if the first path part is in noln as a file or explicit directory.
    # since we have to check the file entry as well, we do this manually instead of calling filter_noln
    local skip=
    local skipdir=
    local pnoln=()
    # debug "$BASH_SOURCE" "$LINENO" "pnoln=(${pnoln[@]})"
    for nolnentry in "${noln[@]}"; do
      debug "$BASH_SOURCE" "$LINENO" nolnentry=$nolnentry p=$p
      case "$nolnentry" in
        "$p") debug "$BASH_SOURCE" "$LINENO" "${INVERT}Skipping $p${NOINVERT}"; skip=1; break ;;
        "$p/") debug "$BASH_SOURCE" "$LINENO" "dir in noln, will skip if hit: $p/"; skipdir=1 ;;
        "$p/"*) pnoln+=($(strip_left_path_part "$nolnentry" "$p")); debug "$BASH_SOURCE" "$LINENO" "pnoln=(${pnoln[@]})" ;;
      esac
    done
    [[ $skip ]] && continue

    # make sure to strip trailing slashes from src and dest before we concatenate with $p,
    # otherwise we might end up with double slashes which can cause problems with string-matching paths
    local srcp="$(strip_trailing_slash "$src")/$p"
    local destp="$(strip_trailing_slash "$dest")/$p"
    debug "$BASH_SOURCE" "$LINENO" "srcp=$srcp destp=$destp"

    # is it a file?  if so, try to link it
    if [[ -f "$srcp" ]] && [[ $skiplevel -le 0 ]]; then
      debug "$BASH_SOURCE" "$LINENO" "Linking file $destp to $srcp"
      safe_link "$srcp" "$destp"
      continue
    fi

    # if we're here's it a directory.  but let's see if we can link to the directory.
    if [[ -d "$srcp" ]]; then
      debug "$BASH_SOURCE" "$LINENO" "srcp is dir: $srcp"
      # does the target already exist as a file?  if so, we can't link to the directory, so skip it.
      [[ -f "$destp" ]] && die "Failed to link $destp to $srcp: target exists as a file"

      # does the target already exist as a directory?
      if [[ -d "$destp" ]]; then
        debug "$BASH_SOURCE" "$LINENO" "destp is dir: $destp"
        # but what if it's a link?
        if [[ -L "$destp" ]]; then
          # where is it linking?
          local linktgt=$(readlink "$destp")  # no -f, do not resolve link, use the nominal path
          debug "$BASH_SOURCE" "$LINENO" "destp is ln $destp -> $linktgt"
          if [[ "$linktgt" == "$DOTPKGDIR/"* ]]; then
            # is it already the link we want?  if so, skip it.
            is_link_match "$srcp" "$destp"
            case $? in
              0)
                debug "$BASH_SOURCE" "$LINENO" "link already exists, skipping"
                continue
                ;;
                # ;&  ### THIS IS INTENTIONALLY WRONG FOR DEBUGGING ONLY
              2)
                # it's one of ours, so we can replace it with a real dir and merge contents
                debug "$BASH_SOURCE" "$LINENO" "${INVERT}Replacing link $destp with real directory${NOINVERT}"
                replace_link_with_dir "$srcp" "$destp" "$linktgt"
                # continue linking below now that the other link is out of the way
                ;;
              1)
                die "Link does not exist (but we shouldn't be here since we already checked?)"
                ;;
              3)
                die "Target exists but is not a link (but we shouldn't be here since we already checked?)"
                ;;
              *)
                die "Unexpected return value from is_link_match"
                ;;
            esac
          else
            # it's not one of ours, so we can't mess with it, so skip it.
            die "target $destp is a link to $linktgt"
          fi
        else
          debug "$BASH_SOURCE" "$LINENO" "Directory $destp is not a link, merging contents"
        fi
      else
        # target does not already exist, so we can link if we're allowed
        if [[ $skipdir == 1 ]]; then
          debug "$BASH_SOURCE" "$LINENO" "${INVERT}Directory $p/ is in noln, skipping${NOINVERT}"
        elif [[ $skiplevel -gt 0 ]]; then
          debug "$BASH_SOURCE" "$LINENO" "${INVERT}skiplevel $skiplevel greater than 0${NOINVERT}"
        else
          debug "$BASH_SOURCE" "$LINENO" "Linking directory $destp to $srcp"
          safe_link "$srcp" "$destp"
          continue
        fi
      fi
      # if we got here, we need to merge, or we need to skip but still need to descend the tree.
      # either the dir exists or we aren't supposed to make a link
      local pkgdir=$(extract_pkgdir_from_path "$srcp")
      local prel=$(strip_pkgdir_from_path "$srcp")
      if should_skip_recurse_pkgdir_path "$pkgdir" "$prel"; then
        debug "$BASH_SOURCE" "$LINENO" "${INVERT}Path $prel is in pkgdir norecurse${NOINVERT}"
        continue
      else
        # let's just mkdir -p to be safe in case we need it later.
        mkdir -p "$destp" || die "Failed to create directory $destp"
        debug "$BASH_SOURCE" "$LINENO" "Descending into directory $srcp to merge with $destp"
        pull_src_dest_skiplevel_noln "$srcp" "$destp" $((skiplevel - 1)) "${pnoln[@]}"
        continue
      fi
    fi

    # if we're here, it's not a file or directory.  what could it be??
    error "file: $(file -b "$srcp") $srcp is not a file or directory, skipping"
  done
}

msys2_pkg_install() {
  local pkgdir="$1"
  local msys2file="$pkgdir/msys2"
  if [ -f "$msys2file" ]; then
    msys2pkgs=$(parse_pattern_file "$msys2file")
    if [ -z "$msys2pkgs" ]; then
      warn "No MSYS2 packages found in $msys2file"
      return 1
    fi
    pkg_info "* Installing MSYS2 packages for $msys2file:"
    for line in $msys2pkgs; do
      pkg_info "  * $line"
    done
    pacboy -S --noconfirm --needed $msys2pkgs || die "Failed to install MSYS2 packages"
    echo
  fi
}

pull_pkg() {
  local pkg="$1"
  local pkgdir="$DOTPKGDIR/$pkg"
  echo
  pkg_info "${INVERT}$pkg ($pkgdir)${NOINVERT}"

  msys2_pkg_install "$pkgdir"

  local pull_home_noln=()
  local pull_root_noln=()
  local pull_userprofile_noln=()
  noln_for_pkgdir_home_root_userprofile "$pkgdir" pull_home_noln pull_root_noln pull_userprofile_noln

  if [ -d "$pkgdir/home" ]; then
    pkg_info "* Pulling home for package $pkg"
    [ -f "$pkgdir/pre-home.sh" ] && . "$pkgdir/pre-home.sh"
    pull_src_dest_skiplevel_noln "$pkgdir/home" ~ 0 "${HOME_NOLN[@]}" "${pull_home_noln[@]}"
  fi

  if [ -d "$pkgdir/root" ]; then
    pkg_info "* Pulling root for package $pkg"
    [ -f "$pkgdir/pre-root.sh" ] && . "$pkgdir/pre-root.sh"
    pull_src_dest_skiplevel_noln "$pkgdir/root" "" 1 "${ROOT_NOLN[@]}" "${pull_root_noln[@]}"
  fi

  if [ -d "$pkgdir/userprofile" -a -d "$USERPROFILE" ]; then
    pkg_info "* Pulling userprofile for package $pkg"
    CYGPATH_USERPROFILE=$(cygpath -ua "$USERPROFILE")
    [ -f "$pkgdir/pre-userprofile.sh" ] && . "$pkgdir/pre-userprofile.sh"
    pull_src_dest_skiplevel_noln "$pkgdir/userprofile" "$CYGPATH_USERPROFILE" 0 "${USERPROFILE_NOLN[@]}" "${pull_userprofile_noln[@]}"
  fi
}
