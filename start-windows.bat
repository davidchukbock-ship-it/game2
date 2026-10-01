@echo off
rem One-click launcher for Windows. Needs no installers, no Docker, no admin rights:
rem it downloads portable Node.js and cloudflared, runs PostgreSQL from an npm package.
rem Run by double-click or from cmd. First start takes a few minutes.
cd /d "%~dp0"
title Throne Clash launcher

net session >nul 2>nul
if not errorlevel 1 (
  echo [!] This window is running as Administrator. PostgreSQL refuses to start that way.
  echo     Close it, open a NORMAL cmd ^(Start - type cmd - Enter, do NOT choose "Run as administrator"^)
  echo     and run start-windows.bat again.
  pause & exit /b 1
)

set "TOOLS=%USERPROFILE%\tc-tools"
if exist "%USERPROFILE%\node-portable\node.exe" set "PATH=%USERPROFILE%\node-portable;%PATH%"
if exist "%TOOLS%\cloudflared.exe" set "PATH=%TOOLS%;%PATH%"

where node >nul 2>nul
if errorlevel 1 (
  echo [1/6] Downloading portable Node.js...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\get-node.ps1"
  if errorlevel 1 ( echo [!] Could not download Node.js. Check the internet and run again. & pause & exit /b 1 )
  set "PATH=%USERPROFILE%\node-portable;%PATH%"
)

where pnpm >nul 2>nul
if errorlevel 1 (
  echo [2/6] Installing pnpm...
  call npm install -g pnpm
  if errorlevel 1 ( echo [!] pnpm install failed & pause & exit /b 1 )
)

where cloudflared >nul 2>nul
if errorlevel 1 (
  echo [3/6] Downloading cloudflared - public link tool...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\get-cloudflared.ps1"
  if errorlevel 1 ( echo [!] Could not download cloudflared & pause & exit /b 1 )
  set "PATH=%TOOLS%;%PATH%"
)

echo [4/6] Installing game packages (first time takes a few minutes)...
call pnpm install || goto :fail

echo [5/6] Starting the database...
start "Throne Clash - database (do not close)" cmd /k pnpm db:embedded
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\wait-port.ps1" -Port 5432
if errorlevel 1 ( echo [!] The database did not start - look at the "database" window and send a screenshot. & pause & exit /b 1 )
call pnpm db:generate || goto :fail
call pnpm db:migrate || goto :fail

echo [6/6] Starting the game...
set "REDIS_URL=none"
start "Throne Clash - game (do not close)" cmd /k pnpm dev
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\wait-port.ps1" -Port 5173 -Seconds 90
start "" http://localhost:5173
echo.
echo Local game: http://localhost:5173
echo Public link appears below as https://....trycloudflare.com  (keep all windows open)
echo.
call pnpm share
pause
exit /b 0

:fail
echo.
echo [!] A step failed - send a screenshot of this window.
pause
exit /b 1
