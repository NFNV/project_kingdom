#!/bin/bash
set -e
overworld_demo_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
overworld_project_dir="$(cd -- "$overworld_demo_dir/../.." && pwd)"
overworld_godot_binary=""
for overworld_candidate in /Applications/Godot.app/Contents/MacOS/Godot "$HOME/Applications/Godot.app/Contents/MacOS/Godot" "$HOME/Downloads/Godot.app/Contents/MacOS/Godot"; do
    if [ -x "$overworld_candidate" ]; then
        overworld_godot_binary="$overworld_candidate"
        break
    fi
done
if [ -z "$overworld_godot_binary" ]; then
    overworld_godot_binary="$(command -v godot || command -v godot4 || true)"
fi
if [ -z "$overworld_godot_binary" ]; then
    echo "Godot was not found. Open world.tscn in Godot and press F6."
    read -r -p "Press Return to close. "
    exit 1
fi
exec "$overworld_godot_binary" --path "$overworld_project_dir" res://experiments/overworld_2d_v01/world.tscn "$@"
