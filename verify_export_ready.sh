#!/bin/bash
# Export Verification Script for AngryGirlFriend Game
# Run this before exporting to verify everything is ready

echo "================================"
echo "  EXPORT READINESS CHECK"
echo "================================"
echo ""

# Check if we're in the right directory
if [ ! -f "project.godot" ]; then
    echo "[ERROR] project.godot not found!"
    echo "Please run this script from the project root directory."
    exit 1
fi

echo "[OK] Found project.godot"

# Check for export presets
if [ ! -f "export_presets.cfg" ]; then
    echo "[ERROR] export_presets.cfg not found!"
    echo "Please ensure export presets are configured."
    exit 1
fi

echo "[OK] Found export_presets.cfg"

# Check main scene
if grep -q "run/main_scene" project.godot; then
    echo "[OK] Main scene configured"
else
    echo "[WARN] Main scene not configured"
fi

# Check for Builds directory
if [ ! -d "Builds" ]; then
    echo "[INFO] Creating Builds directory..."
    mkdir -p Builds
fi

echo "[OK] Builds directory ready"

# Check for critical files
ERRORS=0

if [ ! -f "autoload/game_state.gd" ]; then
    echo "[ERROR] Missing autoload/game_state.gd"
    ((ERRORS++))
else
    echo "[OK] GameState autoload exists"
fi

if [ ! -f "systems/mood_analyzer.gd" ]; then
    echo "[ERROR] Missing systems/mood_analyzer.gd"
    ((ERRORS++))
else
    echo "[OK] MoodAnalyzer system exists"
fi

if [ ! -f "addons/player2/plugin.cfg" ]; then
    echo "[ERROR] Missing Player2 addon"
    ((ERRORS++))
else
    echo "[OK] Player2 addon exists"
fi

# Check for macOS resource forks
if find . -name "._*" -type f | grep -q .; then
    echo "[WARN] Found macOS resource fork files (._*)"
    echo "       Run: find . -name '._*' -type f -delete"
fi

# Check for .import.png files
if find . -name "*.import.png" | grep -q .; then
    echo "[WARN] Found .import.png files - these may cause issues"
    echo "       Run: find . -name '*.import.png' -delete"
fi

echo ""
echo "================================"
if [ $ERRORS -eq 0 ]; then
    echo "  RESULT: READY TO EXPORT!"
    echo "================================"
    echo ""
    echo "Next steps:"
    echo "1. Open project in Godot 4.6"
    echo "2. Go to Project > Export"
    echo "3. Select platform and click Export Project"
    echo "4. Your executable will be in the Builds/ folder"
    echo ""
else
    echo "  RESULT: $ERRORS ERROR(S) FOUND"
    echo "================================"
    echo "Please fix the errors listed above before exporting."
    echo ""
fi
