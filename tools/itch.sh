#!/usr/bin/env bash
# Exports the web build and packs it for itch.io: build/mainspring-web.zip (index.html at the root).
# On itch: Kind of project = HTML, upload the zip, tick "This file will be played in the browser",
# Viewport 1280x720 with "Mobile friendly" (landscape) and the fullscreen button enabled.
set -e
cd "$(dirname "$0")/.."
tools/web.sh > /dev/null
rm -f build/mainspring-web.zip
(cd build/web && zip -qr ../mainspring-web.zip . -x '*.import')
ls -lh build/mainspring-web.zip
