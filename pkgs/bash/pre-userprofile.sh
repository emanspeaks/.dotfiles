#!/usr/bin/env bash
# this file is sourced by pull.sh, so any functions or variables there are available here

checkfiles=(
  "$CYGPATH_USERPROFILE/.bash_profile"
  "$CYGPATH_USERPROFILE/.profile"
  "$CYGPATH_USERPROFILE/.bashrc"
)
fixfiles=0
for file in "${checkfiles[@]}"; do
  if [ -e "$file" ] && [ ! -L "$file" ]; then
    warn "Bash files exist in home directory already.  Do you want to replace them with symlinks to the dotfiles versions?"
    read -p "(y/n) " yn
    case $yn in
      [Yy]* ) fixfiles=1; break;;
      * ) die "Dotfiles cannot proceed with existing Bash files.";;
    esac
  fi
done
if [ $fixfiles -eq 1 ]; then
  for file in "${checkfiles[@]}"; do
    if [ -f "$file" ]; then
      rm -v "$file" || die "Failed to remove existing file $file"
    fi
  done
fi
