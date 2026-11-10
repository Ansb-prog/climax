@echo off
cd /d "%~dp0"
if not exist .venv ( py -3 -m venv .venv || python -m venv .venv )
call .venv\Scripts\activate.bat
python -m pip install -q --upgrade pip
python -m pip install -q -r requirements-pipeline.txt
python -m pipeline.run_all %*
python -m unittest discover -s tests -p "test_*.py"
echo Real data ready. Start the app with START_WINDOWS.bat
pause
