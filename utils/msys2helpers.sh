get_win_env_assocref() {
  local -n assocref="$1"
  # We need to check the actual Windows environment, not just the one filtered through bash.
  # The best way to do that I can come up with is to check /proc/<pid>/environ for the parent of the shell,
  # which we assume is the process whose PPID is 1.
  local testpid=$$
  local testppid=$PPID
  while [[ $testppid -ne 1 ]]; do
    testpid=$testppid
    testppid=$(cat /proc/$testpid/ppid)
  done
  local parentpid=$testpid
  local ttycheck=$(cat /proc/$parentpid/ctty)
  if [ -n "$ttycheck" ]; then
    # wezterm launches the shell directly, so it doesn't have mintty as a buffer.
    # this won't be blank in that case.  Still not sure what to do about it.
    warn "expected blank tty for PID $parentpid, got '$ttycheck'."
    warn "Environment checks for Windows may not be accurate of host system."
  fi
  envlines=()
  readarray -t envlines < <(tr '\0' '\n' < /proc/$parentpid/environ)
  for line in "${envlines[@]}"; do
    key="${line%%=*}"
    value="${line#*=}"
    assocref["$key"]="$value"
  done
}

win_env_ensure_value() {
  local key="$1"
  local value="$2"
  local -n winenv_ref="$3"
  local current="${winenv_ref[$key]}"
  if [[ "$current" != "$value" ]]; then
    warn "Setting Windows env var $key='$(path_echo $value)' (was '$(path_echo $current)')"
    setx "$key" "$value" 2>&1 >/dev/null || die "Failed to set Windows env var $key='$(path_echo $value)'"
    return 1
  else
    debug "$BASH_SOURCE" "$LINENO" "Windows env var already $key='$(path_echo $value)'"
    return 0
  fi
}

win_reg_get_value() {
  # returns [key, value, type, data] in the resultref array
  local -n resultref="$1"
  local key="$2"
  local value="$3"
  local valflag
  [ -z "$value" ] && valflag='//ve' || valflag='//v'
  local regout
  resultref=()  # clear resultref in case reg query fails
  # do not quote vars here; will cause syntax error in reg query
  regout=$(reg query $key $valflag $value 2>/dev/null) || return 1
  resultref=($(tr -d '\r' <<< "$regout"))
}

win_reg_set_value() {
  local key="$1"
  local value="$2"
  local type="$3"
  local data="$4"
  local valflag
  local typeflag
  local dataflag
  [ -z "$value" ] && valflag='//ve' || valflag='//v'
  [ -z "$type" ] || typeflag='//t'
  [ -z "$data" ] || dataflag='//d'
  # do not quote vars here; will cause syntax error in reg add
  # echo reg add $key //f $valflag $value $typeflag $type $dataflag $data
  reg add $key //f $valflag $value $typeflag $type $dataflag $data 2>&1 >/dev/null || return 1
}

win_reg_ensure_value() {
  local key="$1"
  local value="$2"
  local type="$3"
  local data="$4"
  local result=()
  local needupdate=0
  win_reg_get_value result "$key" "$value" || needupdate=1
  local matchtype="${type:-REG_SZ}"
  if [[ $needupdate -eq 1 || "${result[2]}" != "$matchtype" || "${result[3]}" != "$data" ]]; then
    warn "Upserting reg $(path_echo $key) :: $value type=$type data=$(path_echo $data)"
    win_reg_set_value "$key" "$value" "$type" "$data" || die "Failed to set reg $(path_echo $key) :: $value type=$type data=$(path_echo $data)"
    return 1
  else
    debug "$BASH_SOURCE" "$LINENO" "No reg change needed: $(path_echo $key) :: $value type=$type data=$(path_echo $data)"
  fi
}
