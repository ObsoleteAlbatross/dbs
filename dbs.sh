#!/bin/sh

if type xbps-install >/dev/null 2>&1; then
  distro="void"
  install-pkg() { xbps-install -y "$1" > /dev/null 2>&1; }
else
  distro="arch"
  installpkg(){ pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;}
fi

# Setup vim
if command -v nvim >/dev/null 2>&1; then
  echo "Bootstraping Vim"
  nvim '+PlugUpdate' '+PlugClean!' '+PlugUpdate' '+qall'
fi
