#!/bin/bash
set -e
northgate_demo_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
exec "$northgate_demo_dir/Play Garden Square.command" -- --district
