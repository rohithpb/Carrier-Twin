@echo off
echo Starting CareerTwin FastAPI Backend Server on port 8000...
cd /d "%~dp0"
call "backend\venv\Scripts\activate.bat"
python -m uvicorn main:app --app-dir backend --host 0.0.0.0 --port 8000 --reload
pause
