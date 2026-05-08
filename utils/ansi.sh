#!/bin/sh
CSI="\e["

NOANSI="\e[0m"

BOLD="\e[1m"
DIM="\e[2m"
ITALIC="\e[3m"
UNDERLINE="\e[4m"
BLINK="\e[5m"
STROBE="\e[6m"
INVERT="\e[7m"
HIDECHARS="\e[8m"
STRIKE="\e[9m"

NOBOLD="\e[21m"
NODIM="\e[22m"
NOITALIC="\e[23m"
NOUNDERLINE="\e[24m"
NOBLINK="\e[25m"
NOSTROBE="\e[26m"
NOINVERT="\e[27m"
SHOWCHARS="\e[28m"
NOSTRIKE="\e[29m"


DEFAULTFG="\e[0;39m"

BLACK="\e[0;30m"
DKRED="\e[0;31m"
DKGREEN="\e[0;32m"
DKYELLOW="\e[0;33m"
DKBLUE="\e[0;34m"
DKMAGENTA="\e[0;35m"
DKCYAN="\e[0;36m"
LTGRAY="\e[0;37m"

DKGRAY="\e[0;90m"
RED="\e[0;91m"
GREEN="\e[0;92m"
YELLOW="\e[0;93m"
BLUE="\e[0;94m"
MAGENTA="\e[0;95m"
CYAN="\e[0;96m"
WHITE="\e[0;97m"


DEFAULTBG="\e[0;49m"

BLACKBG="\e[0;40m"
DKREDBG="\e[0;41m"
DKGREENBG="\e[0;42m"
DKYELLOWBG="\e[0;43m"
DKBLUEBG="\e[0;44m"
DKMAGENTABG="\e[0;45m"
DKCYANBG="\e[0;46m"
LTGRAYBG="\e[0;47m"

DKGRAYBG="\e[0;100m"
REDBG="\e[0;101m"
GREENBG="\e[0;102m"
YELLOWBG="\e[0;103m"
BLUEBG="\e[0;104m"
MAGENTABG="\e[0;105m"
CYANBG="\e[0;106m"
WHITEBG="\e[0;107m"

stylecombo() {
  # example usage: stylecombo $BOLD $RED "This is bold red text" $NOANSI
  local style=0
  local fg=39
  local bg=49
  while [ "$#" -gt 0 ]; do
    local stripcsi="${1#"$CSI"}"
    local colorcode="${stripcsi##*;}"
    local colornum="${colorcode%m}"
    # echo $stripcsi $colorcode $colornum
    if [ $colornum -lt 30 ]; then
      style=$colornum
    elif [ $colornum -lt 40 ]; then
      fg=$colornum
    elif [ $colornum -lt 50 ]; then
      bg=$colornum
    elif [ $colornum -lt 100 ]; then
      fg=$colornum
    elif [ $colornum -lt 110 ]; then
      bg=$colornum
    else
      die "Invalid color code: $colornum"
    fi
    shift
  done
  echo "$CSI${style};${fg};${bg}m"
}
