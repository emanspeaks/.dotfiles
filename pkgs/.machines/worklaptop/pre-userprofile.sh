#!/usr/bin/env bash
# this file is sourced by pull.sh, so any functions or variables there are available here
if [ -n "$HOMEDRIVE" ] && [[ "$HOMEDRIVE" != "C:" ]]; then
  setx HOMEDRIVE "C:"
  setx HOMEPATH "\\Users\\$USERNAME"
fi
