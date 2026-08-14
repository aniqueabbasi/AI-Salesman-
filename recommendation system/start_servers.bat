@echo off
echo Starting Product Recommendation System...

echo Starting Backend API Server...
start cmd /k "python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"

echo Starting Frontend Server...
start cmd /k "python frontend/server.py"

echo Servers started!
echo Backend API: http://localhost:8000
echo Frontend: http://localhost:8080
echo.
echo Press any key to open the frontend in your browser...
pause > nul
start http://localhost:8080 