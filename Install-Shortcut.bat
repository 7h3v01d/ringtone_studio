@echo off
rem One-time setup: lets the website's "Send to iPhone" button start this helper.
reg add "HKCU\Software\Classes\ringtonesender" /ve /d "URL:Ringtone Sender" /f >nul
reg add "HKCU\Software\Classes\ringtonesender" /v "URL Protocol" /d "" /f >nul
reg add "HKCU\Software\Classes\ringtonesender\shell\open\command" /ve /d "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%~dp0Send-Ringtone.ps1\" \"%%1\"" /f >nul
echo.
echo Done! The "Send to iPhone" button on the website now works.
echo Keep this folder where it is (if you move it, run this file again).
pause
