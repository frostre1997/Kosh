#!/system/bin/sh
export HOME=/storage/emulated/0
export PS1='localhost@hostname:\w# '
cd /storage/emulated/0
mkdir -p /data/data/com.kosh.shell.dev/files/bin
export PATH=/data/data/com.kosh.shell.dev/files/bin:$PATH
echo 'export PATH=/data/data/com.kosh.shell.dev/files/bin:$PATH' >> /data/data/com.kosh.shell.dev/files/.profile
echo "150.1.01.0" > /data/data/com.kosh.shell.dev/files/.kosh_version

cat > /data/data/com.kosh.shell.dev/files/bin/k << 'SCRIPT'
#!/system/bin/sh
VERSION=$(cat /data/data/com.kosh.shell.dev/files/.kosh_version 2>/dev/null || echo "150.1.01.0")
show_help() {
    cat << HELP
Kosh v$VERSION
Official flags:
  --h             Show this help
  --st            Show storage info
  --uptm          Show system uptime
  --dinf          Show device info (model, Android version, kernel)
  --ip            Show IP address(es)
  --dns           Show DNS servers
  --update        Check for app updates
HELP
}
case "$1" in
    --h) show_help ;;
    --st) /data/data/com.kosh.shell.dev/files/bin/storage ;;
    --uptm) /data/data/com.kosh.shell.dev/files/bin/uptime ;;
    --dinf) /data/data/com.kosh.shell.dev/files/bin/deviceinfo ;;
    --ip) /data/data/com.kosh.shell.dev/files/bin/ipinfo ;;
    --dns) /data/data/com.kosh.shell.dev/files/bin/dnsinfo ;;
    --update) /data/data/com.kosh.shell.dev/files/bin/update ;;
    *) show_help ;;
esac
SCRIPT
chmod +x /data/data/com.kosh.shell.dev/files/bin/k

cat > /data/data/com.kosh.shell.dev/files/bin/storage << 'SCRIPT'
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
chmod +x /data/data/com.kosh.shell.dev/files/bin/storage

cat > /data/data/com.kosh.shell.dev/files/bin/uptime << 'SCRIPT'
#!/system/bin/sh
uptime_seconds=$(cat /proc/uptime | cut -d. -f1)
days=$((uptime_seconds / 86400))
hours=$(( (uptime_seconds % 86400) / 3600 ))
mins=$(( (uptime_seconds % 3600) / 60 ))
echo "Uptime: ${days}d ${hours}h ${mins}m"
SCRIPT
chmod +x /data/data/com.kosh.shell.dev/files/bin/uptime

cat > /data/data/com.kosh.shell.dev/files/bin/deviceinfo << 'SCRIPT'
#!/system/bin/sh
echo "Device: $(getprop ro.product.model 2>/dev/null || echo "Unknown")"
echo "Android: $(getprop ro.build.version.release 2>/dev/null || echo "Unknown") (API $(getprop ro.build.version.sdk 2>/dev/null || echo "?"))"
echo "Kernel: $(uname -r 2>/dev/null || echo "Unknown")"
echo "Architecture: $(uname -m 2>/dev/null || echo "Unknown")"
SCRIPT
chmod +x /data/data/com.kosh.shell.dev/files/bin/deviceinfo

cat > /data/data/com.kosh.shell.dev/files/bin/ipinfo << 'SCRIPT'
#!/system/bin/sh
echo "Wi‑Fi IP:"
ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "No Wi‑Fi IP"
echo "Mobile IP:"
ip addr show rmnet0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "No mobile IP"
SCRIPT
chmod +x /data/data/com.kosh.shell.dev/files/bin/ipinfo

cat > /data/data/com.kosh.shell.dev/files/bin/dnsinfo << 'SCRIPT'
#!/system/bin/sh
echo "DNS Servers:"
cat /etc/resolv.conf 2>/dev/null | grep nameserver | awk '{print $2}' || echo "No DNS configuration found."
SCRIPT
chmod +x /data/data/com.kosh.shell.dev/files/bin/dnsinfo

cat > /data/data/com.kosh.shell.dev/files/bin/update << 'SCRIPT'
#!/system/bin/sh
echo "Checking for updates..."
LATEST=$(curl -s https://api.github.com/repos/frostre1997/Kosh/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
if [ -n "$LATEST" ]; then
    echo "Latest version: $LATEST"
    echo "Current version: $(cat /data/data/com.kosh.shell.dev/files/.kosh_version)"
    if [ "$LATEST" != "$(cat /data/data/com.kosh.shell.dev/files/.kosh_version)" ]; then
        echo "A new version is available. Download from:"
        echo "https://github.com/frostre1997/Kosh/releases"
    else
        echo "You are up to date."
    fi
else
    echo "Could not check for updates."
fi
SCRIPT
chmod +x /data/data/com.kosh.shell.dev/files/bin/update

cat > /data/data/com.kosh.shell.dev/files/bin/!! << 'SCRIPT'
#!/system/bin/sh
LAST=$(tail -n 2 /data/data/com.kosh.shell.dev/files/.ash_history | head -n 1 | sed 's/^[ \t]*//')
if [ -n "$LAST" ]; then
    echo "$LAST"
    eval "$LAST"
else
    echo "No previous command."
fi
SCRIPT
chmod +x /data/data/com.kosh.shell.dev/files/bin/!!

cat > /data/data/com.kosh.shell.dev/files/bin/!!! << 'SCRIPT'
#!/system/bin/sh
echo "Last 10 commands:"
tail -n 10 /data/data/com.kosh.shell.dev/files/.ash_history | cat -n
SCRIPT
chmod +x /data/data/com.kosh.shell.dev/files/bin/!!!

cat > /data/data/com.kosh.shell.dev/files/bin/bg << 'SCRIPT'
#!/system/bin/sh
if [ -z "$1" ]; then
    echo "Usage: bg <command> [args...]"
    exit 1
fi
nohup "$@" </dev/null >/dev/null 2>&1 &
echo "Background job started: $!"
SCRIPT
chmod +x /data/data/com.kosh.shell.dev/files/bin/bg

cat > /data/data/com.kosh.shell.dev/files/bin/! << 'SCRIPT'
#!/system/bin/sh
echo "!"
SCRIPT
chmod +x /data/data/com.kosh.shell.dev/files/bin/!

echo "alias sp='suspend'" >> /data/data/com.kosh.shell.dev/files/.profile
echo "alias rs='resume'" >> /data/data/com.kosh.shell.dev/files/.profile
echo "alias help='k --h'" >> /data/data/com.kosh.shell.dev/files/.profile
echo "alias storage='k --st'" >> /data/data/com.kosh.shell.dev/files/.profile
echo "alias uptime='k --uptm'" >> /data/data/com.kosh.shell.dev/files/.profile
echo "alias device='k --dinf'" >> /data/data/com.kosh.shell.dev/files/.profile
echo "alias ip='k --ip'" >> /data/data/com.kosh.shell.dev/files/.profile
echo "alias dns='k --dns'" >> /data/data/com.kosh.shell.dev/files/.profile

# ─── Wakelock script using broadcast ─────────────────────────────
cat > /data/data/com.kosh.shell.dev/files/bin/wakelock << 'SCRIPT'
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
chmod +x /data/data/com.kosh.shell.dev/files/bin/wakelock
