@echo off
chcp 65001 > nul
echo =====================================================================
echo  DONG BO DU LIEU DATABASE: IMPORT TU GIT VAO CONTAINER
echo =====================================================================
python sync_data.py import
echo.
pause
