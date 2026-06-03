#!/usr/bin/env bash
eval "$(pixi completion --shell bash)"
if [ ! -f .envrc ]; then
  if [ -f pixi.toml ] || ([ -f pyproject.toml ] && grep -q "^\[tool.pixi" pyproject.toml); then
    eval "$(pixi shell-hook)"
  fi
fi
