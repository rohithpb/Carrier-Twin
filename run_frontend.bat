@echo off
echo Starting CareerTwin Flutter Frontend...
echo Available targets: chrome, edge, windows
cd /d "%~dp0"
flutter run -d chrome --web-port 3000
pause
