#!/usr/bin/env bash
# This script is intended to help bootstrap a new install of MSYS2 with the minimum necessary packages.
# Keeping this lightweight in case we ever need or want to run it by itself without a full dotfiles deploy.
pacman -Syuu
pacman -S --noconfirm --needed pactoys
