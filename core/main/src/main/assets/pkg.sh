#!/system/bin/sh
PKG_DIR="$HOME/.kosh-packages"
mkdir -p "$PKG_DIR"
REPO_URL="https://raw.githubusercontent.com/frostre1997/kosh-packages/main/packages.json"
PACKAGE_FILE="/tmp/packages.json"
if [ "$1" = "list" ]; then
    curl -s "$REPO_URL" -o "$PACKAGE_FILE"
    cat "$PACKAGE_FILE" | grep -o '"name": "[^"]*"' | sed 's/"name": "//;s/"//'
elif [ "$1" = "install" ]; then
    PACKAGE="$2"
    curl -s "$REPO_URL" -o "$PACKAGE_FILE"
    URL=$(cat "$PACKAGE_FILE" | grep -A2 "\"$PACKAGE\"" | grep '"url"' | sed 's/.*"url": "\([^"]*\)".*/\1/')
    if [ -z "$URL" ]; then
        echo "Package '$PACKAGE' not found."
        exit 1
    fi
    echo "Downloading $PACKAGE from $URL"
    curl -L -o "/tmp/$PACKAGE.tar.gz" "$URL"
    mkdir -p "$PKG_DIR/$PACKAGE"
    tar -xzf "/tmp/$PACKAGE.tar.gz" -C "$PKG_DIR/$PACKAGE"
    rm "/tmp/$PACKAGE.tar.gz"
    mkdir -p "$HOME/.local/bin"
    for BIN in "$PKG_DIR/$PACKAGE"/*; do
        if [ -f "$BIN" ] && [ -x "$BIN" ]; then
            ln -sf "$BIN" "$HOME/.local/bin/$(basename $BIN)" 2>/dev/null
        fi
    done
    echo "Installed $PACKAGE"
else
    echo "Usage: pkg list | install <package>"
fi
