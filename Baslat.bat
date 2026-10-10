@echo off
chcp 65001 >nul
cd /d "%~dp0"
set "PS1_FILE=%~dp0OtoKapat.ps1"

powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList @('-WindowStyle', 'Hidden', '-STA', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $env:PS1_FILE + '"')) -WindowStyle Hidden"
exit
