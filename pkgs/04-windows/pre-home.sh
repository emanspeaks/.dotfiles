#!/usr/bin/env bash
# this file is sourced by pull.sh, so any functions or variables there are available here

touch /c/scratch/git/.gitignore
if ! (sc qc ssh-agent | grep -q "START_TYPE         : 3   DEMAND_START"); then
  info configuring ssh-agent
  sudo sc config ssh-agent start= demand || die failed to configure ssh-agent
fi

# fix ssh perms
# 1. Remove inheritance and keep current permissions as explicit ones
if [ -d "$SECRETSDIR/plaintext/.ssh" ]; then
  info setting permissions for ssh private keys
  for key in "$SECRETSDIR/plaintext/.ssh/"*.pub; do
    local privkey="${key%.pub}"
    if [ -f "$privkey" ]; then
      icacls "$privkey" //inheritance:d
      icacls "$privkey" //remove "Everyone"
      icacls "$privkey" //remove "BUILTIN\\Users"
      icacls "$privkey" //remove "NT AUTHORITY\\Authenticated Users"
      icacls "$privkey" //grant $(whoami):RW
    fi
  done
fi
