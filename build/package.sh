#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Most recent git tag
VERSION="$(git -C "$SCRIPT_DIR/.." describe --tags --abbrev=0)"

echo "Using version: $VERSION"

echo "Creating linux archive..."
(
    cd "$SCRIPT_DIR/linux"
    zip -r "../ghost-channel-linux-${VERSION}.zip" ghost-channel
)

echo "Creating macOS archive..."
(
    cd "$SCRIPT_DIR/mac"
    zip -r "../ghost-channel-mac-${VERSION}.zip" ghost-channel.app
)

echo "Creating web archive..."
(
    cd "$SCRIPT_DIR/web"
    zip -r "../ghost-channel-web-${VERSION}.zip" .
)

echo "Creating windows archive..."
(
    cd "$SCRIPT_DIR/win"
    zip -r "../ghost-channel-win-${VERSION}.zip" ghost-channel
)

echo "Done!"