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
  regout=$(reg query $key $valflag $value) || return 1
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
  [ -z "$type" ] || typeflag="/t $type"
  [ -z "$data" ] || dataflag="/d $data"
  # do not quote vars here; will cause syntax error in reg add
  reg add $key /f $valflag $value $typeflag $type $dataflag $data || return 1
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
    debug "$BASH_SOURCE" "$LINENO" "Upserting reg $key :: $value type=$type data=$data"
    win_reg_set_value "$key" "$value" "$type" "$data" || die "Failed to set reg $key :: $value type=$type data=$data"
    return 1
  else
    debug "$BASH_SOURCE" "$LINENO" "No reg change needed: $key :: $value type=$type data=$data"
  fi
}
