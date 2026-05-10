parse_pattern_file() {
  local path="$1"
  [ -f "$path" ] && (cat "$path" | sed 's/^[[:space:]]*//;s/#[[:print:]]*$//;s/[[:space:]]*$//' | grep . | sort -u)
}

parse_pattern_file_linesref() {
  local path="$1"
  local -n linesref="$2"
  if [ -f "$path" ]; then
    readarray -t linesref < <(parse_pattern_file "$path")
    return 0
  else
    linesref=()
    return 1
  fi
}

add_pkg_drop_marker() {
  # find the line in $DOTMACHFILE corresponding to $pkg, and prepend it with //
  local content=$(sed -E "s/^([[:space:]]*)${1}([[:space:]]*(#.*)?\$)/\1\/\/${1}\2/" "$DOTMACHFILE")
  printf '%s\n' "$content" > "$DOTMACHFILE"
}

comment_pkg_drop_marker() {
  # find the line in $DOTMACHFILE corresponding to $pkg, and prepend it with //
  local content=$(sed -E "s/^([[:space:]]*)\/\/${1}([[:space:]]*(#.*)?\$)/\1#${1}\2/" "$DOTMACHFILE")
  printf '%s\n' "$content" > "$DOTMACHFILE"
}
