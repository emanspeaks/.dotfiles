#!/usr/bin/env bash
# eval "$(direnv hook bash)"

export _DIRENV_PATH="$(command -v direnv)"

# manual direnv hook that fixes slash problems
# see https://github.com/direnv/direnv/issues/343#issuecomment-398868227
# allow PS1 changes
# see https://github.com/direnv/direnv/issues/1381
_direnv_hook() {
  local previous_exit_status=$?;
  trap -- '' SIGINT;
  export _DIRENV_LAST_PS1="$PS1"
  export _DIRENV_LAST_PATH="$PATH"
  export DIRENV_PS1="$PS1"
  eval "$("$_DIRENV_PATH" export bash)";
  [[ "$PATH" != "$_DIRENV_LAST_PATH" ]] && export PATH="$(echo $PATH | /usr/bin/sed -E 's/C:/\/c/g' | /usr/bin/sed -E 's/\\/\//g' | /usr/bin/sed -E 's/;/:/g')"
  [[ "$DIRENV_PS1" != "$_DIRENV_LAST_PS1" ]] && export PS1="${DIRENV_PS1}"
  trap - SIGINT;
  return $previous_exit_status;
};

add_prompt_cmd _direnv_hook
