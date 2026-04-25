@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
chcp 65001 >nul
cd /d "%SCRIPT_DIR%"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%scripts\start-web-debug.ps1"
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
  echo.
  echo Web debug startup failed. Exit code: %EXIT_CODE%
  pause
)

endlocal
exit /b %EXIT_CODE%
