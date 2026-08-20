#!/system/bin/sh
export HOME=/storage/emulated/0
export PS1='localhost@hostname:\w# '
cd /storage/emulated/0
mkdir -p /root/bin
export PATH=/root/bin:$PATH
echo 'export PATH=/root/bin:$PATH' >> /root/.profile
echo "150.1.01.0" > /root/.kosh_version

cat > /root/bin/k << 'SCRIPT'
#!/system/bin/sh
VERSION=$(cat /root/.kosh_version 2>/dev/null || echo "150.1.01.0")
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
    --st) /root/bin/storage ;;
    --uptm) /root/bin/uptime ;;
    --dinf) /root/bin/deviceinfo ;;
    --ip) /root/bin/ipinfo ;;
    --dns) /root/bin/dnsinfo ;;
    --update) /root/bin/update ;;
    *) show_help ;;
esac
SCRIPT
chmod +x /root/bin/k

cat > /root/bin/storage << 'SCRIPT'
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
chmod +x /root/bin/storage

cat > /root/bin/uptime << 'SCRIPT'
#!/system/bin/sh
uptime_seconds=$(cat /proc/uptime | cut -d. -f1)
days=$((uptime_seconds / 86400))
hours=$(( (uptime_seconds % 86400) / 3600 ))
mins=$(( (uptime_seconds % 3600) / 60 ))
echo "Uptime: ${days}d ${hours}h ${mins}m"
SCRIPT
chmod +x /root/bin/uptime

cat > /root/bin/deviceinfo << 'SCRIPT'
#!/system/bin/sh
echo "Device: $(getprop ro.product.model 2>/dev/null || echo "Unknown")"
echo "Android: $(getprop ro.build.version.release 2>/dev/null || echo "Unknown") (API $(getprop ro.build.version.sdk 2>/dev/null || echo "?"))"
echo "Kernel: $(uname -r 2>/dev/null || echo "Unknown")"
echo "Architecture: $(uname -m 2>/dev/null || echo "Unknown")"
SCRIPT
chmod +x /root/bin/deviceinfo

cat > /root/bin/ipinfo << 'SCRIPT'
#!/system/bin/sh
echo "Wi‑Fi IP:"
ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "No Wi‑Fi IP"
echo "Mobile IP:"
ip addr show rmnet0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "No mobile IP"
SCRIPT
chmod +x /root/bin/ipinfo

cat > /root/bin/dnsinfo << 'SCRIPT'
#!/system/bin/sh
echo "DNS Servers:"
cat /etc/resolv.conf 2>/dev/null | grep nameserver | awk '{print $2}' || echo "No DNS configuration found."
SCRIPT
chmod +x /root/bin/dnsinfo

cat > /root/bin/update << 'SCRIPT'
#!/system/bin/sh
echo "Checking for updates..."
LATEST=$(curl -s https://api.github.com/repos/frostre1997/Kosh/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
if [ -n "$LATEST" ]; then
    echo "Latest version: $LATEST"
    echo "Current version: $(cat /root/.kosh_version)"
    if [ "$LATEST" != "$(cat /root/.kosh_version)" ]; then
        echo "A new version is available. Download from:"
        echo "https://github.com/frostre1997/Kosh/releases"
    else
        echo "You are up to date."
    fi
else
    echo "Could not check for updates."
fi
SCRIPT
chmod +x /root/bin/update

cat > /root/bin/!! << 'SCRIPT'
#!/system/bin/sh
LAST=$(tail -n 2 /root/.ash_history | head -n 1 | sed 's/^[ \t]*//')
if [ -n "$LAST" ]; then
    echo "$LAST"
    eval "$LAST"
else
    echo "No previous command."
fi
SCRIPT
chmod +x /root/bin/!!

cat > /root/bin/!!! << 'SCRIPT'
#!/system/bin/sh
echo "Last 10 commands:"
tail -n 10 /root/.ash_history | cat -n
SCRIPT
chmod +x /root/bin/!!!

cat > /root/bin/bg << 'SCRIPT'
#!/system/bin/sh
if [ -z "$1" ]; then
    echo "Usage: bg <command> [args...]"
    exit 1
fi
nohup "$@" </dev/null >/dev/null 2>&1 &
echo "Background job started: $!"
SCRIPT
chmod +x /root/bin/bg

cat > /root/bin/! << 'SCRIPT'
#!/system/bin/sh
echo "!"
SCRIPT
chmod +x /root/bin/!

echo "alias sp='suspend'" >> /root/.profile
echo "alias rs='resume'" >> /root/.profile
echo "alias help='k --h'" >> /root/.profile
echo "alias storage='k --st'" >> /root/.profile
echo "alias uptime='k --uptm'" >> /root/.profile
echo "alias device='k --dinf'" >> /root/.profile
echo "alias ip='k --ip'" >> /root/.profile
echo "alias dns='k --dns'" >> /root/.profile
