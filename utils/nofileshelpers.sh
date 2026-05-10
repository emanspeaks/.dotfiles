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
    parse_pattern_file_linesref "$pkgdir_nolnfile" pkgdir_noln
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
  debug "$BASH_SOURCE" "$LINENO" "Adding norecurse map pkg=$pkg array_name=$array_name pkgidx=$pkgidx"
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
  debug "$BASH_SOURCE" "$LINENO" "Getting norecurse for pkgdir=$pkgdir pkg=$pkg"
  norecurse_array_ref=$(get_pkg_norecurse_arrayname "$pkg")
  if [ $? -ne 0 ]; then
    local norecursefile="$pkgdir/norecurse"
    if [ -f "$norecursefile" ]; then
      debug "$BASH_SOURCE" "$LINENO" found norecurse file "$norecursefile"
      parse_pattern_file_linesref "$norecursefile" norecurse_array_ref
    fi
  fi
  echo "${norecurse_array_ref[@]}"
}

should_skip_recurse_pkgdir_path() {
  local pkgdir="$1"
  local path=$(strip_trailing_slash "$2")
  array_contains "$path/" "$(get_pkgdir_norecurse "$pkgdir")"
}

filter_noln_for_path_nolnref() {
  local path="$1"
  # declare -n newnoln_ref="$2"
  local pkgdir=$(extract_pkgdir_from_path "$path")  # /home/user/.dotfiles/pkgs/bar
  local nolnrelpath=$(strip_pkgdir_from_path "$path")  # home/.config
  debug "$BASH_SOURCE" "$LINENO" pkgdir="$pkgdir" nolnrelpath="$nolnrelpath"
  local home_noln=()
  local root_noln=()
  local userprofile_noln=()
  noln_for_pkgdir_home_root_userprofile "$pkgdir" home_noln root_noln userprofile_noln
  case "$path" in
    "$pkgdir/home/"*)
      filter_noln $2 "${nolnrelpath#home/}" "${home_noln[@]}"
      ;;
    "$pkgdir/root/"*)
      filter_noln $2 "${nolnrelpath#root/}" "${root_noln[@]}"
      ;;
    "$pkgdir/userprofile/"*)
      filter_noln $2 "${nolnrelpath#userprofile/}" "${userprofile_noln[@]}"
      ;;
    *)
      die "Link target $path is not in home, root, or userprofile"
      ;;
  esac
}
