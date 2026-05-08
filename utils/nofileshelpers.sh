filter_noln() {
  declare -n newnoln_ref="$1"
  local parent="$2"
  shift 2
  local filtnoln=("$@")
  newnoln_ref=()
  for nolnentry in "${filtnoln[@]}"; do
    debug "$BASH_SOURCE" "$LINENO" "nolnentry=$nolnentry parent=$parent, newnoln_ref=(${newnoln_ref[@]})"
    [[ "$nolnentry" == $parent/* ]] && newnoln_ref+=($(strip_left_path_part "$nolnentry" "$parent"))
  done
}

noln_for_pkgdir_home_root_userprofile() {
  local pkgdir="$1"
  declare -n home_noln_ref="$2"
  declare -n root_noln_ref="$3"
  declare -n userprofile_noln_ref="$4"
  home_noln_ref=()
  root_noln_ref=()
  userprofile_noln_ref=()


  local pkgdir_nolnfile="$pkgdir/noln"
  local pkgdir_noln=()

  if [ -f "$pkgdir_nolnfile" ]; then
    debug "$BASH_SOURCE" "$LINENO" found noln file "$pkgdir_nolnfile"
    readarray -t pkgdir_noln < "$pkgdir_nolnfile"
    filter_noln home_noln_ref "home" "${pkgdir_noln[@]}"
    filter_noln root_noln_ref "root" "${pkgdir_noln[@]}"
    filter_noln userprofile_noln_ref "userprofile" "${pkgdir_noln[@]}"
  fi
}

declare -A NORECURSE_PKG2IDX
NORECURSE_LAST_IDX=0

add_pkg_array_to_norecurse_map() {
  local pkg=$1
  local pkgidx=$((NORECURSE_LAST_IDX + 1))
  local array_name="norecurse_array_$pkgidx"
  NORECURSE_LAST_IDX=$pkgidx
  NORECURSE_PKG2IDX[$pkg]=$pkgidx
  eval "declare -ga $array_name=()"
  echo "$array_name"
}

get_pkg_norecurse_arrayname() {
  local pkg=$1
  if [[ -v "NORECURSE_PKG2IDX[$pkg]" ]]; then
    local pkgidx="${NORECURSE_PKG2IDX[$pkg]}"
    echo "norecurse_array_$pkgidx"
  else
    add_pkg_array_to_norecurse_map "$pkg"
    return 1
  fi
}

get_pkgdir_norecurse() {
  local pkgdir="$1"
  local pkg=$(pkgdir_to_name "$pkgdir")
  local -n norecurse_array_ref
  norecurse_array_ref=$(get_pkg_norecurse_arrayname "$pkg")
  if [ $? -ne 0 ]; then
    local norecursefile="$pkgdir/norecurse"
    if [ -f "$norecursefile" ]; then
      debug "$BASH_SOURCE" "$LINENO" found norecurse file "$norecursefile"
      readarray -t norecurse_array_ref < "$norecursefile"
    fi
  fi
  echo "${norecurse_array_ref[@]}"
}

should_skip_recurse_pkgdir_path() {
  local pkgdir="$1"
  local path=$(strip_trailing_slash "$2")
  get_pkgdir_norecurse "$pkgdir" | tr ' ' '\n' | grep -x "$path/" > /dev/null
  return $?
}
