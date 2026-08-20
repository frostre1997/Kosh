#!/system/bin/sh

# ─── Detect writable app directory ────────────────────────────────
SCRIPT_PATH="$(realpath "$0" 2>/dev/null || echo "$0")"
APP_DATA_DIR="$(echo "$SCRIPT_PATH" | sed -E 's|(/data/user/[0-9]+/[^/]+)/local/bin/init-host$|\1|')"

if [ -z "$APP_DATA_DIR" ] || [ ! -d "$APP_DATA_DIR" ]; then
    # Fallback: use HOME if set, otherwise default debug path
    if [ -n "$HOME" ] && [ -d "$HOME" ]; then
        APP_DATA_DIR="$HOME"
    else
        APP_DATA_DIR="/data/user/0/com.kosh.shell.dev"
    fi
fi

export HOME="$APP_DATA_DIR/files"
mkdir -p "$HOME/bin"
export PATH="$HOME/bin:$PATH"

# ─── Write version file ────────────────────────────────────────────
echo "150.1.01.0" > "$HOME/.kosh_version"

# ─── Define `k` command ───────────────────────────────────────────
cat > "$HOME/bin/k" << 'SCRIPT'
#!/system/bin/sh
VERSION=$(cat "$HOME/.kosh_version" 2>/dev/null || echo "150.1.01.0")
show_help() {
    cat << HELP
Kosh v$VERSION
Official flags:
  --h             Show this help
  --st            Show storage info
  --uptm          Show system uptime
  --dinf          Show device info
  --ip            Show IP address(es)
  --dns           Show DNS servers
  --update        Check for app updates
HELP
}
case "$1" in
    --h) show_help ;;
    --st) "$HOME/bin/storage" ;;
    --uptm) "$HOME/bin/uptime" ;;
    --dinf) "$HOME/bin/deviceinfo" ;;
    --ip) "$HOME/bin/ipinfo" ;;
    --dns) "$HOME/bin/dnsinfo" ;;
    --update) "$HOME/bin/update" ;;
    *) show_help ;;
esac
SCRIPT
chmod +x "$HOME/bin/k"

# ─── Sub‑commands ──────────────────────────────────────────────────
cat > "$HOME/bin/storage" << 'SCRIPT'
#!/system/bin/sh
echo "=== Internal Storage (/storage/emulated/0) ==="
df -h /storage/emulated/0 | grep -v Filesystem | awk '{print "Size: "$2 "  Used: "$3 "  Avail: "$4 "  Use%: "$5}'
echo ""
echo "=== External SD Card (if present) ==="
SD=$(mount | grep "/storage/" | grep -v "emulated" | awk '{print $3}')
if [ -n "$SD" ]; then
    df -h "$SD" | grep -v Filesystem | awk '{print "Size: "$2 "  Used: "$3 "  Avail: "$4 "  Use%: "$5}'
else
    echo "No external SD card found."
fi
SCRIPT
chmod +x "$HOME/bin/storage"

cat > "$HOME/bin/uptime" << 'SCRIPT'
#!/system/bin/sh
uptime_seconds=$(cat /proc/uptime | cut -d. -f1)
days=$((uptime_seconds / 86400))
hours=$(( (uptime_seconds % 86400) / 3600 ))
mins=$(( (uptime_seconds % 3600) / 60 ))
echo "Uptime: ${days}d ${hours}h ${mins}m"
SCRIPT
chmod +x "$HOME/bin/uptime"

cat > "$HOME/bin/deviceinfo" << 'SCRIPT'
#!/system/bin/sh
echo "Device: $(getprop ro.product.model 2>/dev/null || echo "Unknown")"
echo "Android: $(getprop ro.build.version.release 2>/dev/null || echo "Unknown") (API $(getprop ro.build.version.sdk 2>/dev/null || echo "?"))"
echo "Kernel: $(uname -r 2>/dev/null || echo "Unknown")"
echo "Architecture: $(uname -m 2>/dev/null || echo "Unknown")"
SCRIPT
chmod +x "$HOME/bin/deviceinfo"

cat > "$HOME/bin/ipinfo" << 'SCRIPT'
#!/system/bin/sh
echo "Wi‑Fi IP:"
ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "No Wi‑Fi IP"
echo "Mobile IP:"
ip addr show rmnet0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "No mobile IP"
SCRIPT
chmod +x "$HOME/bin/ipinfo"

cat > "$HOME/bin/dnsinfo" << 'SCRIPT'
#!/system/bin/sh
echo "DNS Servers:"
cat /etc/resolv.conf 2>/dev/null | grep nameserver | awk '{print $2}' || echo "No DNS configuration found."
SCRIPT
chmod +x "$HOME/bin/dnsinfo"

cat > "$HOME/bin/update" << 'SCRIPT'
#!/system/bin/sh
echo "Checking for updates..."
LATEST=$(curl -s https://api.github.com/repos/frostre1997/Kosh/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
if [ -n "$LATEST" ]; then
    echo "Latest version: $LATEST"
    echo "Current version: $(cat "$HOME/.kosh_version")"
    if [ "$LATEST" != "$(cat "$HOME/.kosh_version")" ]; then
        echo "A new version is available. Download from:"
        echo "https://github.com/frostre1997/Kosh/releases"
    else
        echo "You are up to date."
    fi
else
    echo "Could not check for updates."
fi
SCRIPT
chmod +x "$HOME/bin/update"

# ─── Quick commands ──────────────────────────────────────────────
cat > "$HOME/bin/!!" << 'SCRIPT'
#!/system/bin/sh
LAST=$(tail -n 2 "$HOME/.ash_history" 2>/dev/null | head -n 1 | sed 's/^[ \t]*//')
if [ -n "$LAST" ]; then
    echo "$LAST"
    eval "$LAST"
else
    echo "No previous command."
fi
SCRIPT
chmod +x "$HOME/bin/!!"

cat > "$HOME/bin/!!!" << 'SCRIPT'
#!/system/bin/sh
echo "Last 10 commands:"
tail -n 10 "$HOME/.ash_history" 2>/dev/null | cat -n
SCRIPT
chmod +x "$HOME/bin/!!!"

cat > "$HOME/bin/bg" << 'SCRIPT'
#!/system/bin/sh
if [ -z "$1" ]; then
    echo "Usage: bg <command> [args...]"
    exit 1
fi
nohup "$@" </dev/null >/dev/null 2>&1 &
echo "Background job started: $!"
SCRIPT
chmod +x "$HOME/bin/bg"

cat > "$HOME/bin/!" << 'SCRIPT'
#!/system/bin/sh
echo "!"
SCRIPT
chmod +x "$HOME/bin/!"

# ─── Wakelock command (broadcast) ────────────────────────────────
cat > "$HOME/bin/wakelock" << 'SCRIPT'
#!/system/bin/sh
case "$1" in
    -y|--yes)
        am broadcast -a com.kosh.shell.TOGGLE_WAKELOCK
        echo "Wakelock toggled (dialog will open if needed)."
        ;;
    -r|--raw)
        am broadcast -a com.kosh.shell.TOGGLE_WAKELOCK
        echo "Wakelock toggled (no dialog)."
        ;;
    -s|--status)
        dumpsys power | grep -q "mHoldingWakeLockSuspendBlocker" && echo "Wakelock held" || echo "Wakelock not held"
        ;;
    -h|--help)
        echo "Usage: wakelock [-y|-r|-s|-h]"
        echo "  -y, --yes     Toggle wakelock (may open battery dialog)"
        echo "  -r, --raw     Toggle wakelock immediately (no dialog)"
        echo "  -s, --status  Show current wakelock status"
        echo "  -h, --help    Show this help"
        ;;
    *)
        am broadcast -a com.kosh.shell.TOGGLE_WAKELOCK
        echo "Wakelock toggled."
        ;;
esac
SCRIPT
chmod +x "$HOME/bin/wakelock"

# ─── Aliases and PS1 ──────────────────────────────────────────────
echo "alias sp='suspend'" >> "$HOME/.profile"
echo "alias rs='resume'" >> "$HOME/.profile"
echo "alias help='k --h'" >> "$HOME/.profile"
echo "alias storage='k --st'" >> "$HOME/.profile"
echo "alias uptime='k --uptm'" >> "$HOME/.profile"
echo "alias device='k --dinf'" >> "$HOME/.profile"
echo "alias ip='k --ip'" >> "$HOME/.profile"
echo "alias dns='k --dns'" >> "$HOME/.profile"
echo "export PATH=\$HOME/bin:\$PATH" >> "$HOME/.profile"
echo "export PS1='localhost@hostname:\\w# '" >> "$HOME/.profile"

# ─── Start the shell in the external storage ──────────────────────
cd /storage/emulated/0 2>/dev/null || cd /sdcard 2>/dev/null || exit 1
exec /system/bin/sh -l
