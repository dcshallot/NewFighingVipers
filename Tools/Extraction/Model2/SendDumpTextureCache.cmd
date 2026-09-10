@echo off
where pwsh.exe >nul 2>nul || (echo PowerShell 7 ^(pwsh.exe^) is required. & exit /b 1)
pwsh.exe -NoProfile -File "%~dp0SendDumpTextureCache.ps1" %*
