get_win_env_assocref() {
  local -n assocref="$1"
  # We need to check the actual Windows environment, not just the one filtered through bash.
  # The best way to do that I can come up with is to check /proc/<pid>/environ for the parent of the shell,
  # which we assume is our parent
  local ttypid=$(cat /proc/$PPID/ppid)
  local ttycheck=$(cat /proc/$ttypid/ctty)
  [ -z "$ttycheck" ] || die "expected blank tty for PID $ttypid, got '$ttycheck'"
  envlines=()
  readarray -t envlines < <(tr '\0' '\n' < /proc/$ttypid/environ)
  for line in "${envlines[@]}"; do
    key="${line%%=*}"
    value="${line#*=}"
    assocref["$key"]="$value"
  done
}
