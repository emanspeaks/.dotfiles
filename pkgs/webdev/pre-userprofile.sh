#!/usr/bin/env bash
# this file is sourced by pull.sh, so any functions or variables there are available here

if [[ $(get_machine_name) != worklaptop ]]; then
  winget install Schniz.fnm
fi
