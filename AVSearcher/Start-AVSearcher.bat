@echo off
setlocal
chcp 65001 >nul

set "SCRIPT=%~dp0AVSearcher.ps1"

:: Launch with hidden console and permissive policy just for this run
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT%"

exit /b 0
