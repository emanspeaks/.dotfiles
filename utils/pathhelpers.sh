pkg_name_to_pkgdir() {
  echo "$(realpath "$DOTPKGDIR")/$1"
}

abs_path_cwd() {
  local effcwd="$2"
  if [ -n "$effcwd" ]; then
    realpath -s --relative-to="$effcwd" "$1" 2>/dev/null
  else
    realpath -s "$1" 2>/dev/null
  fi
}

strip_dotfiles_from_path() {
  local path=$(abs_path_cwd "$1" "$2")
  if [[ "$path" == "$DOTFILES/"* ]]; then
    echo "${path#"$DOTFILES/"}"
  else
    echo "$1"
  fi
}

strip_machines_from_path() {
  local path=$(abs_path_cwd "$1" "$2")
  if [[ "$path" == "$DOTMACHDIR/"* ]]; then
    echo "${path#"$DOTMACHDIR/"}"
  else
    echo "$1"
  fi
}

strip_pkgdirroot_from_path() {
  local path=$(abs_path_cwd "$1" "$2")
  if [[ "$path" == "$DOTPKGDIR/"* ]]; then
    echo "${path#"$DOTPKGDIR/"}"
  else
    die "Path $path is not in DOTPKGDIR=$DOTPKGDIR"
  fi
}

pkgdir_to_name() {
  strip_pkgdirroot_from_path "$1" | cut -d/ -f1
}

extract_pkgdir_from_path() {
  local relpath=$(strip_pkgdirroot_from_path "$1")
  pkg_name_to_pkgdir "${relpath%%/*}"
}

strip_pkgdir_from_path() {
  local relpath=$(strip_pkgdirroot_from_path "$1")
  echo "${relpath#*/}"
}

strip_left_path_part() {
  echo "${1#"$2/"}"
}

strip_trailing_slash() {
  echo "${1%/}"
}

strip_leftmost_path_part() {
  echo "${1#*/}"
}
