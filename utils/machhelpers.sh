MACHINEPKG=base-machine

get_machine_name() {
  [ -L "$DOTMACHFILE" ] || return 1
  strip_machines_from_path "$(readlink -f "$DOTMACHFILE")"
}

try_link_machine_pkgdir() {
  local machine=$(get_machine_name)
  local truepkgdir="$DOTPKGDIR/.machines/$machine"
  local pkgdir="$(pkg_name_to_pkgdir "$MACHINEPKG")"
  debug "$BASH_SOURCE" "$LINENO" "try_link_machine_pkgdir: machine=$machine truepkgdir=$truepkgdir pkgdir=$pkgdir"
  breakpoint "$BASH_SOURCE" "$LINENO"
  if [ -d "$truepkgdir" ]; then
    debug "$BASH_SOURCE" "$LINENO" "Found machine-specific package directory $truepkgdir"
    ln -sv "$truepkgdir" "$pkgdir"
    return 0
  else
    debug "$BASH_SOURCE" "$LINENO" "No machine-specific package directory found $truepkgdir"
    return 1
  fi
}

init_machine_base_pkgdir() {
  [[ -L "$(pkg_name_to_pkgdir "$MACHINEPKG")" ]] && return 0
  try_link_machine_pkgdir
}
