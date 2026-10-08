@echo off
reg delete "HKCU\Software\Classes\ringtonesender" /f >nul
echo The "Send to iPhone" website button has been disconnected.
pause
