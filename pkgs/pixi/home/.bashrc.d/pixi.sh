#!/usr/bin/env bash
eval "$(pixi completion --shell bash)"
if [ ! -f .envrc ] && ([ -f pixi.toml ] || [ -f pyproject.toml ]); then
  eval "$(pixi shell-hook)"
fi
