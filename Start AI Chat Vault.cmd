@echo off
title AI Chat Vault
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0AI-Chat-Vault.ps1"
if errorlevel 1 pause
