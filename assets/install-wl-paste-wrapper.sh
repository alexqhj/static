#!/bin/bash
# Install wl-paste wrapper for image paste support in Claude Code on WSL2
# Source: https://github.com/anthropics/claude-code/issues/13738#issuecomment-3947404694
set -e

echo "Installing dependencies..."
sudo apt install -y imagemagick wl-clipboard

echo "Installing wl-paste wrapper..."
cat << 'WRAPPER' | sudo tee /usr/local/bin/wl-paste > /dev/null
#!/usr/bin/env bash
# wl-paste wrapper for WSL2 — adds BMP→PNG conversion for Claude Code
# Delegates everything to the real wl-paste, only intercepts BMP→PNG.
REAL_WL_PASTE="/usr/bin/wl-paste"

# Detect --list-types or -l
if [[ " $* " == *" --list-types "* ]] || [[ " $* " == *" -l "* ]]; then
    output=$("$REAL_WL_PASTE" "$@" 2>/dev/null)
    rc=$?
    echo "$output"
    if echo "$output" | grep -q 'image/bmp' && ! echo "$output" | grep -q 'image/png'; then
        echo "image/png"
    fi
    exit $rc
fi

# Detect --type image/png
if [[ " $* " == *" --type image/png "* ]] || [[ " $* " =~ --type\ image/png$ ]]; then
    "$REAL_WL_PASTE" "$@" 2>/dev/null && exit 0
    "$REAL_WL_PASTE" --type image/bmp 2>/dev/null | convert bmp:- png:- 2>/dev/null
    exit $?
fi

exec "$REAL_WL_PASTE" "$@"
WRAPPER

sudo chmod +x /usr/local/bin/wl-paste

echo ""
echo "Done! wl-paste wrapper installed at /usr/local/bin/wl-paste"
echo "To uninstall: sudo rm /usr/local/bin/wl-paste"
