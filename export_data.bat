@echo off
chcp 65001 > nul
echo =====================================================================
echo  DONG BO DU LIEU DATABASE: EXPORT VA STAGE LEN GIT
echo =====================================================================
python sync_data.py export
echo.
pause
