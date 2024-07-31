@echo off
cd /d "%~dp0"
Powershell -NoProfile -ExecutionPolicy Bypass -File .\createOusAndDisableUsers.ps1
pause