#!/bin/zsh
set -e

PROJECT_DIR="${0:A:h}"
WORKSPACE_GODOT="$PROJECT_DIR/../../work/godot-runtime/Godot.app/Contents/MacOS/Godot"

if command -v godot >/dev/null 2>&1; then
  GODOT_BIN="$(command -v godot)"
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
  GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
elif [[ -x "$WORKSPACE_GODOT" ]]; then
  GODOT_BIN="$WORKSPACE_GODOT"
elif [[ -x "/Users/sylviaying/Documents/Codex/2026-09-18/wha/work/godot-runtime/Godot.app/Contents/MacOS/Godot" ]]; then
  GODOT_BIN="/Users/sylviaying/Documents/Codex/2026-09-18/wha/work/godot-runtime/Godot.app/Contents/MacOS/Godot"
else
  GODOT_BIN=""
fi

if [[ -z "$GODOT_BIN" ]]; then
  echo "Godot 4.7.2 or newer was not found."
  echo "Download it from https://godotengine.org/download/macos/"
  echo "Then import: $PROJECT_DIR/project.godot"
  read -r "?Press Enter to close."
  exit 1
fi

"$GODOT_BIN" --editor --path "$PROJECT_DIR"
