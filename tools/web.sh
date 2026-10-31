#!/usr/bin/env bash
# Export the web build and (re)start a static server on PORT (default 4957).
# Usage: [HOST=0.0.0.0] tools/web.sh [port]   then open http://localhost:<port>
set -e
cd "$(dirname "$0")/.."
PORT="${1:-4957}"
HOST="${HOST:-127.0.0.1}"
mkdir -p build/web
godot --headless --export-release "Web" build/web/index.html
cp tools/web/manifest.webmanifest tools/web/icon-192.png tools/web/icon-512.png build/web/
if ! curl -s -o /dev/null "http://127.0.0.1:$PORT/"; then
  nohup python3 tools/serve.py "$PORT" "$HOST" > build/server.log 2>&1 &
  sleep 1
fi
echo "Mainspring web build ready: http://localhost:$PORT"
