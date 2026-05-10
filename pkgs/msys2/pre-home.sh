#!/usr/bin/env bash
# this file is sourced by pull.sh, so any functions or variables there are available here
[[ "$MSYS2_PATH_TYPE" == "inherit" ]] || setx MSYS2_PATH_TYPE inherit
