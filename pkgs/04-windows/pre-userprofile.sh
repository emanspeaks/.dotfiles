#!/usr/bin/env bash
# this file is sourced by pull.sh, so any functions or variables there are available here

# Set Win10 context menu as default
# local ctx_menu_script="$DOTPKGDIR/msys2/scripts/restore_win10_context_menu_default.bat"
local reg_changes=0
win_reg_ensure_value 'HKEY_CURRENT_USER\SOFTWARE\CLASSES\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
((reg_changes += $?))
win_reg_ensure_value 'HKEY_CURRENT_USER\SOFTWARE\CLASSES\CLSID\{d93ed569-3b3e-4bff-8355-3c44f6a52bb5}\InprocServer32'
((reg_changes += $?))

# Disable Bing search in Start menu
win_reg_ensure_value 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' REG_DWORD 0x0
((reg_changes += $?))
win_reg_ensure_value 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search' 'AllowSearchToUseLocation' REG_DWORD 0x0
((reg_changes += $?))
win_reg_ensure_value 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent' REG_DWORD 0x0
((reg_changes += $?))

if [[ $reg_changes -gt 0 ]]; then
  info "Some registry changes were made that may require restarting explorer.exe to take effect."
  read -p "Do you want to restart explorer.exe now? [Y/n] " -n 1 yn
  echo
  if [[ $yn =~ ^[Yy]$ || -z "$yn" ]]; then
    warn "Restarting explorer.exe"
    taskkill //f //im explorer.exe
    cmd //i //c "start explorer.exe"
  fi
fi
