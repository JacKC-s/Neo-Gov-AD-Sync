@echo off
cd /d "%~dp0"
Powershell -NoProfile -ExecutionPolicy Bypass -File .\neogovfilter.ps1
pause