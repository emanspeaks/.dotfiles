array_contains() {
  local match="$1"
  shift
  echo "$@" | tr ' ' '\n' | grep -qx "$match"
}
