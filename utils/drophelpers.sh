drop_src_dest_skiplevel_fullnolnref_noln() {
  local src="$1"
  local dest="$2"
  local skiplevel="$3"
  local -n fullnolnref="$4"
  local noln=($(echo "${@:5}" | sort -u))  # remove duplicates just in case
  debug "$BASH_SOURCE" "$LINENO" "drop_src_dest_skiplevel_fullnolnref_noln src=$src dest=$dest skiplevel=$skiplevel noln=(${noln[@]})"
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
    src="$(strip_trailing_slash "$src")"
    dest="$(strip_trailing_slash "$dest")"
    local srcp="$src/$p"
    local destp="$dest/$p"
    debug "$BASH_SOURCE" "$LINENO" "srcp=$srcp destp=$destp"

    # is it a link?  if so, try to clean up
    if [[ $skiplevel -le 0 ]] && [[ -L "$destp" ]]; then
      # where is it linking?
      local linktgt=$(readlink "$destp")  # no -f, do not resolve link, use the nominal path
      if is_link_match "$srcp" "$destp" 1; then
        debug "$BASH_SOURCE" "$LINENO" "Link $destp -> $srcp confirmed, removing link"
        debug "$BASH_SOURCE" "$LINENO" rm -v "$destp"
        breakpoint "$BASH_SOURCE" "$LINENO"
        rm -v "$destp" || die "Failed to remove link $destp"
      else
        warn "$BASH_SOURCE" "$LINENO" "Link does not exist, skipping"
      fi

      # does dest still have contents after removing the link?
      # first check skiplevel; since we're looking up one dir, add one
      local checklevel=$((skiplevel + 1))
      [[ $checklevel -gt 0 ]] && debug "$BASH_SOURCE" "$LINENO" "${INVERT}dir above: dest=$dest skiplevel=$checklevel, skipping cleanup" && continue
      # we only need to check this if dest is not in noln
      # because if it's in noln, we shouldn't try to touch it.
      # stripped src should be equivalent to dest stripped of its "base"
      local nolndir="$(strip_leftmost_path_part "$(strip_pkgdir_from_path "$src")")"
      debug "$BASH_SOURCE" "$LINENO" match="$nolndir/" "array=(${fullnolnref[@]})"
      breakpoint "$BASH_SOURCE" "$LINENO"
      if array_contains "$nolndir/" "${fullnolnref[@]}"; then
        debug "$BASH_SOURCE" "$LINENO" "Dir $nolndir/ in full noln, skipping empty check"
        continue
      fi
      # ok we are not in noln or skiplevel, so we can proceed with cleanup
      local destremain=$(find -L "$dest" -mindepth 1 -print -quit)
      if [[ -z "$destremain" ]]; then
        debug "$BASH_SOURCE" "$LINENO" "Dir $dest is now empty, rmdir"
        if [[ -d "$dest" ]]; then
          debug "$BASH_SOURCE" "$LINENO" rmdir -v "$dest"
          breakpoint "$BASH_SOURCE" "$LINENO"
          rmdir -v "$dest" || die "Failed to remove directory $dest"
        else
          if [[ -L "$dest" ]]; then
            debug "$BASH_SOURCE" "$LINENO" rm -v "$dest"
            breakpoint "$BASH_SOURCE" "$LINENO"
            rm -v "$dest" || die "Failed to remove link $dest"
          fi
        fi
      else
        debug "$BASH_SOURCE" "$LINENO" "Dir $dest still has contents"
        local destpkgs=()
        for testpath in "$destremain"; do
          # we are only interested in symlinks,
          # only clean up if only links remain
          [[ -L "$testpath" ]] || break
          # only proceed if all links are ours
          linktgt=$(readlink "$testpath") # no -f, do not resolve link, use the nominal path
          [[ "$linktgt" == "$DOTPKGDIR/"* ]] || break
          destpkgs+=("$(pkgdir_to_name "$(extract_pkgdir_from_path "$linktgt")")")
        done
        destpkgs=($(echo "${destpkgs[@]}" | tr ' ' '\n' | sort -u ))
        if [[ ${#destpkgs[@]} -eq 0 ]]; then
          debug "$BASH_SOURCE" "$LINENO" "No pkg links remain in $dest, skipping cleanup"
        elif [[ ${#destpkgs[@]} -eq 1 ]]; then
          local pkg="${destpkgs[0]}"
          debug "$BASH_SOURCE" "$LINENO" "Only pkg $pkg links remain in $dest, performing cleanup"
          replace_dir_with_link "$src" "$dest" $((++skiplevel)) || die "Failed to replace directory $dest with link to $src"
        else
          debug "$BASH_SOURCE" "$LINENO" "Multiple pkg links remain in $dest, skipping cleanup"
        fi
      fi
    elif [[ -d "$destp" ]]; then
      # if we got here, we need to descend the tree.
      local pkgdir=$(extract_pkgdir_from_path "$srcp")
      local prel=$(strip_pkgdir_from_path "$srcp")
      if should_skip_recurse_pkgdir_path "$pkgdir" "$prel"; then
        debug "$BASH_SOURCE" "$LINENO" "${INVERT}Path $prel is in pkgdir norecurse${NOINVERT}"
        continue
      else
        debug "$BASH_SOURCE" "$LINENO" "Descending into directory $srcp ($destp)"
        drop_src_dest_skiplevel_fullnolnref_noln "$srcp" "$destp" $((skiplevel - 1)) $4 "${pnoln[@]}"
        continue
      fi
    fi
    # if we got here, idk my bff jill
  done
}

drop_pkg() {
  local pkg="$1"
  local pkgdir="$DOTPKGDIR/$pkg"
  drop_info "DROP: $pkg ($pkgdir)"
  local drop_home_filenoln=()
  local drop_root_filenoln=()
  local drop_userprofile_filenoln=()
  noln_for_pkgdir_home_root_userprofile "$pkgdir" drop_home_filenoln drop_root_filenoln drop_userprofile_filenoln


  if [ -d "$pkgdir/home" ]; then
    pkg_info "* Dropping home for package $pkg"
    local drop_home_noln=("${HOME_NOLN[@]}" "${drop_home_filenoln[@]}")
    drop_src_dest_skiplevel_fullnolnref_noln "$pkgdir/home" ~ 0 drop_home_noln "${drop_home_noln[@]}"
  fi

  if [ -d "$pkgdir/root" ]; then
    pkg_info "* Dropping root for package $pkg"
    local drop_root_noln=("${ROOT_NOLN[@]}" "${drop_root_filenoln[@]}")
    drop_src_dest_skiplevel_fullnolnref_noln "$pkgdir/root" / 1 drop_root_noln "${drop_root_noln[@]}"
  fi

  if [ -d "$pkgdir/userprofile" -a -d "$USERPROFILE" ]; then
    pkg_info "* Dropping userprofile for package $pkg"
    local drop_userprofile_noln=("${USERPROFILE_NOLN[@]}" "${drop_userprofile_filenoln[@]}")
    drop_src_dest_skiplevel_fullnolnref_noln "$pkgdir/userprofile" "$(cygpath -ua "$USERPROFILE")" 0 drop_userprofile_noln "${drop_userprofile_noln[@]}"
  fi
}
