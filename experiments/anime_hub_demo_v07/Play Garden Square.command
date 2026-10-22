#!/bin/bash
set -e
hub_demo_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
hub_project_dir="$(cd -- "$hub_demo_dir/../.." && pwd)"
hub_godot_binary=""
for hub_candidate in /Applications/Godot.app/Contents/MacOS/Godot "$HOME/Applications/Godot.app/Contents/MacOS/Godot" "$HOME/Downloads/Godot.app/Contents/MacOS/Godot"; do
    if [ -x "$hub_candidate" ]; then
        hub_godot_binary="$hub_candidate"
        break
    fi
done
if [ -z "$hub_godot_binary" ]; then
    hub_godot_binary="$(command -v godot || command -v godot4 || true)"
fi
if [ -z "$hub_godot_binary" ]; then
    echo "Godot was not found. Open demo.tscn in Godot and press F6."
    read -r -p "Press Return to close. "
    exit 1
fi
exec "$hub_godot_binary" --path "$hub_project_dir" res://experiments/anime_hub_demo_v07/demo.tscn
