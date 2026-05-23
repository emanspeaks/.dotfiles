#!/usr/bin/env bash
# eval "$(direnv hook bash)"

export _DIRENV_PATH="$(command -v direnv)"

# manual direnv hook that fixes slash problems
# see https://github.com/direnv/direnv/issues/343#issuecomment-398868227
_direnv_hook() {
  local previous_exit_status=$?;
  trap -- '' SIGINT;
  eval "$("$_DIRENV_PATH" export bash)";
  export PATH="$(echo $PATH | /usr/bin/sed -E 's/C:/\/c/g' | /usr/bin/sed -E 's/\\/\//g' | /usr/bin/sed -E 's/;/:/g')"
  trap - SIGINT;
  return $previous_exit_status;
};

if [[ ";${PROMPT_COMMAND[*]:-};" != *";_direnv_hook;"* ]]; then
  if [[ "$(declare -p PROMPT_COMMAND 2>&1)" == "declare -a"* ]]; then
    PROMPT_COMMAND=(_direnv_hook "${PROMPT_COMMAND[@]}")
  else
    PROMPT_COMMAND="_direnv_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
  fi
fi
