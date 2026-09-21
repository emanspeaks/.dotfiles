#!/usr/bin/env bash
# this file is sourced by pull.sh, so any functions or variables there are available here

mkdir -p ~/.local/fonts
cd ~/.local/fonts
[ -f JetBrainsMonoNerdFontMono-Regular.ttf ] || curl -sfL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.tar.xz | tar -xvJ
[ -f ArimoNerdFont-Regular.ttf ] || curl -sfL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/Arimo.tar.xz | tar -xvJ
[ -f AtkynsonMonoNerdFontMono-Regular.otf ] || curl -sfL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/AtkinsonHyperlegibleMono.tar.xz | tar -xvJ
[ -f CommitMonoNerdFontMono-Regular.otf ] || curl -sfL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/CommitMono.tar.xz | tar -xvJ
[ -f UbuntuNerdFont-Regular.ttf ] || curl -sfL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/Ubuntu.tar.xz | tar -xvJ
if [ ! -d ibm-plex-serif ]; then
  curl -sfLO https://github.com/IBM/plex/releases/download/%40ibm/plex-serif%402.0.0/ibm-plex-serif.zip
  unzip ibm-plex-serif.zip
fi
if [ ! -d ibm-plex-mono ]; then
  curl -sfLO https://github.com/IBM/plex/releases/download/%40ibm/plex-mono%402.5.0/ibm-plex-mono.zip
  unzip ibm-plex-mono.zip
fi


