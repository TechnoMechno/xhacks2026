@echo off
REM Export Verification Script for AngryGirlFriend Game
REM Run this before exporting to verify everything is ready

echo ================================
echo   EXPORT READINESS CHECK
echo ================================
echo.

REM Check if we're in the right directory
if not exist "project.godot" (
    echo [ERROR] project.godot not found!
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

echo [OK] Found project.godot

REM Check for export presets
if not exist "export_presets.cfg" (
    echo [ERROR] export_presets.cfg not found!
    echo Please ensure export presets are configured.
    pause
    exit /b 1
)

echo [OK] Found export_presets.cfg

REM Check main scene
findstr /C:"run/main_scene" project.godot >nul
if errorlevel 1 (
    echo [WARN] Main scene not configured
) else (
    echo [OK] Main scene configured
)

REM Check for Builds directory
if not exist "Builds" (
    echo [INFO] Creating Builds directory...
    mkdir Builds
)

echo [OK] Builds directory ready

REM Check for critical files
set ERRORS=0

if not exist "autoload\game_state.gd" (
    echo [ERROR] Missing autoload/game_state.gd
    set /a ERRORS+=1
) else (
    echo [OK] GameState autoload exists
)

if not exist "systems\mood_analyzer.gd" (
    echo [ERROR] Missing systems/mood_analyzer.gd
    set /a ERRORS+=1
) else (
    echo [OK] MoodAnalyzer system exists
)

if not exist "addons\player2\plugin.cfg" (
    echo [ERROR] Missing Player2 addon
    set /a ERRORS+=1
) else (
    echo [OK] Player2 addon exists
)

REM Check for .import files mess
dir /s /b "*.import.png" 2>nul | findstr /C:".import.png" >nul
if not errorlevel 1 (
    echo [WARN] Found .import.png files - these may cause issues
    echo       Run cleanup: del /s "*.import.png"
)

echo.
echo ================================
if %ERRORS% EQU 0 (
    echo   RESULT: READY TO EXPORT!
    echo ================================
    echo.
    echo Next steps:
    echo 1. Open project in Godot 4.6
    echo 2. Go to Project ^> Export
    echo 3. Select platform and click Export Project
    echo 4. Your executable will be in the Builds/ folder
    echo.
) else (
    echo   RESULT: %ERRORS% ERROR(S) FOUND
    echo ================================
    echo Please fix the errors listed above before exporting.
    echo.
)

pause
