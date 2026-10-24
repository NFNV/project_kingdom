#!/bin/bash
set -e
briarwood_demo_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
exec "$briarwood_demo_dir/Play Garden Square.command" -- --wilds
