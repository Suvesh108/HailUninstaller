@echo off
setlocal EnableDelayedExpansion
title HailUninstaller - Deep Application Removal Tool

:: Check for Administrative privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"\"%~dp0HailUninstaller.ps1\"\" %*' -Verb RunAs"
    exit /b
)

:: Run PowerShell script with bypassed execution policy
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0HailUninstaller.ps1" %*

if %errorLevel% neq 0 (
    echo.
    echo Script completed with exit code %errorLevel%.
    pause
)
