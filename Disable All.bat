@echo off
cd /d "%~dp0"
Powershell -NoProfile -ExecutionPolicy Bypass -File .\disableall.ps1
pause