settitle ()
{
  echo -ne "\e]2;$@\a\e]1;$@\a";
}

export UCRT64_PACKAGE_PREFIX="mingw-w64-ucrt-x86_64"
export CYGPATH_USERPROFILE=$(cygpath -ua "$USERPROFILE")
export PATH="$HOME/.local/bin:$HOME/bin:$CYGPATH_USERPROFILE/.local/bin:$PATH"
export MSYS=winsymlinks:nativestrict

alias nvim=/ucrt64/bin/nvim

PS1="\[\e]0;\w\a\]\[\e[32m\]\u@\h \[\e[35m\]$MSYSTEM\[\e[0m\] \[\e[33m\]\w\[\e[0m\]\[\e[36m\]"
GIT_EXEC_PATH="$(git --exec-path 2>/dev/null)"
COMPLETION_PATH="${GIT_EXEC_PATH%/libexec/git-core}"
COMPLETION_PATH="${COMPLETION_PATH%/lib/git-core}"
COMPLETION_PATH="$COMPLETION_PATH/share/git/completion"
if test -f "$COMPLETION_PATH/git-prompt.sh"
then
  . "$COMPLETION_PATH/git-completion.bash"
  . "$COMPLETION_PATH/git-prompt.sh"
  PS1="$PS1"'\[\033[36m\]'  # change color to cyan
  PS1="$PS1"'`__git_ps1`'   # bash function
fi
PS1="$PS1"'\[\033[0m\]'        # change color
PS1="$PS1"'\n'                 # new line
PS1="$PS1"'$ '                 # prompt: always $
export PS1

alias scr="cd /c/scratch"
alias cdgit="cd /c/scratch/git"

command_not_found_handle() {
  local raw_cmd="$*"
  # Check if the failed command starts with a drive letter 'C'
  if [[ "$1" =~ ^[Cc]: ]]; then
    # 1. Take the whole line
    # 2. Use cygpath to fix the paths
    # 3. Re-run it
    local fixed_cmd=$(echo "$raw_cmd" | sed 's/\\/\//g' | sed -E 's/([A-Z]):\//\/\L\1\//g')
    eval "$fixed_cmd"
    return $?
  fi

  echo "bash: $1: command not found"
  return 127
}
