#!/usr/bin/env bash
# this file is sourced by pull.sh, so any functions or variables there are available here

if [ ! -x ~/.local/bin/direnv ]; then
  curl -sfL https://direnv.net/install.sh | bin_path=~/.local/bin bash
fi
