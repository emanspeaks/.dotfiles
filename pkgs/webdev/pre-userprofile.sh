#!/usr/bin/env bash
# this file is sourced by pull.sh, so any functions or variables there are available here

if [[ $(get_machine_name) != worklaptop ]]; then
  winget install Schniz.fnm
elif ! command -v fnm &> /dev/null; then
  curl -LO https://github.com/Schniz/fnm/releases/download/v1.39.0/fnm-windows.zip -o $TEMP/fnm-windows.zip
  unzip $TEMP/fnm-windows.zip -d ~/.local/bin
  rm $TEMP/fnm-windows.zip
fi
