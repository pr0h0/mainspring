#!/usr/bin/env bash
# Runs the solution verifier: tools/v.sh [level index] [-v]
cd "$(dirname "$0")/.."
timeout 60 godot --headless --path . -s tools/verify.gd -- "$@" < /dev/null 2>&1 | grep -v "^Godot Engine\|^$"
