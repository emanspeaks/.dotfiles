export DEBUG=${DEBUG:-0}
export TRACE=${TRACE:-0}
DEBUGSTYLE=$(stylecombo $LTGRAY $DKGREENBG $BOLD)
BREAKSTYLE=$(stylecombo $WHITE $DKREDBG $BLINK)
DROPSTYLE=$(stylecombo $RED $DKYELLOWBG)
OLDCWD=${OLDCWD:-"$(pwd)"}

breakpoint() {
  if [ "$DEBUG" -gt 0 ]; then
    local bashsrc="$1"  # caller's source file
    local linenum="$2"  # caller's line number
    local DUMMY  # used to pause execution until user presses Enter
    echo -ne "${BREAKSTYLE}[$(strip_dotfiles_from_path "$bashsrc"):$linenum] BREAKPOINT ${NOANSI}"
    read -p " (Press Enter to continue...)" DUMMY
  fi
}

set_trace() {
  local level="${1:-1}"
  export TRACE=$level
  set_debug ${DEBUG:-1}
}

set_debug() {
  local level="${1:-1}"
  export DEBUG=$level
  if [ "$TRACE" -gt 0 ]; then
    # export PS4='+(${BASH_SOURCE#"$DOTFILES/"}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    export PS4='+($(strip_dotfiles_from_path "$BASH_SOURCE" "$OLDCWD"):${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -x
    if [ "$TRACE" -eq 3 ]; then
      trap 'read -p "Line $LINENO: $BASH_COMMAND (Press Enter to continue...)"' DEBUG
    fi
  fi
}

calltrace() {
  if [ "$TRACE" -eq 2 ]; then
    echo -e "${DKRED}$@${NOANSI}" >&2
  fi
}

success() {
  echo -e "${GREEN}$@${NOANSI}"
}

pkg_info() {
  echo -e "${BLUE}$@${NOANSI}"
}

drop_info() {
  echo -e "${DROPSTYLE}$@${NOANSI}"
}

info() {
  echo -e "${CYAN}$@${NOANSI}"
}

warn() {
  echo -e "${YELLOW}$@${NOANSI}" >&2
}

error() {
  echo -e "${RED}$@${NOANSI}" >&2
}

critical() {
  echo -e "${MAGENTA}$@${NOANSI}" >&2
}

debug() {
  if [ "$DEBUG" -gt 0 ]; then
    local bashsrc
    local linenum
    local prefix="${DEBUGSTYLE}[DEBUG]${NOANSI}"
    if [ "$DEBUG" -eq 2 ]; then
      bashsrc="$1"  # caller's source file
      linenum="$2"  # caller's line number
      prefix="\n${DEBUGSTYLE}[$(strip_dotfiles_from_path "$bashsrc"):$linenum]${NOANSI}"
    fi
    shift 2
    echo -e "${prefix} ${DKGRAY}$@${NOANSI}" >&2
  fi
}

die() {
  critical "$@"
  exit 1
}
