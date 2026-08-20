#!/system/bin/sh

# ─── Setup prompt and storage commands ────────────────────────────
if [ ! -f /root/.profile ]; then
    # Use the real path (not symlink) as HOME
    echo "export HOME=/storage/emulated/0" > /root/.profile
    echo "export PS1='localhost@hostname:\\w# '" >> /root/.profile

    # ─── Create a `storageinfo` command ────────────────────────────
    mkdir -p /root/bin
    cat > /root/bin/storageinfo << 'SCRIPT'
#!/system/bin/sh
echo "=== Primary Storage (internal) ==="
PRIMARY=$(readlink -f /sdcard 2>/dev/null || echo "/storage/emulated/0")
echo "  Real path: /storage/emulated/0"
echo "  Symlink: /sdcard -> $PRIMARY"
echo "  Usage: $(df -h /storage/emulated/0 2>/dev/null | grep -v Filesystem | awk '{print $3 " used, " $4 " free"}')"
echo ""
echo "=== All External Storage Volumes ==="
for MOUNT in $(mount | grep -E "/storage/|/mnt/media_rw" | awk '{print $3}' | sort -u); do
    if [ "$MOUNT" = "/storage/emulated" ] || [ "$MOUNT" = "/storage/emulated/0" ]; then
        continue
    fi
    if [ -d "$MOUNT" ]; then
        SIZE=$(df -h "$MOUNT" 2>/dev/null | grep -v Filesystem | awk '{print $2 " total, " $3 " used, " $4 " free"}')
        echo "  $MOUNT: $SIZE"
    fi
done
if ! mount | grep -q -E "/storage/[^/]+/[0-9a-zA-Z-]+"; then
    echo "  No external SD card found."
fi
SCRIPT
    chmod +x /root/bin/storageinfo

    # ─── Also keep the old `storage` command for quick free space ──
    cat > /root/bin/storage << 'SCRIPT'
#!/system/bin/sh
echo "=== Internal Storage (/storage/emulated/0) ==="
df -h /storage/emulated/0 | grep -v Filesystem
echo ""
echo "=== External SD Card (if present) ==="
SDCARD_MOUNT=$(mount | grep "/storage/" | grep -v "emulated" | awk '{print $3}')
if [ -n "$SDCARD_MOUNT" ]; then
    df -h "$SDCARD_MOUNT" | grep -v Filesystem
else
    echo "No external SD card found."
fi
SCRIPT
    chmod +x /root/bin/storage

    # Add /root/bin to PATH
    echo 'export PATH="/root/bin:$PATH"' >> /root/.profile
fi

# ─── Proot command ──────────────────────────────────────────────────
# Start directly in the real path, not the symlink
proot -r "$ALPINE_ROOT" \
     -b /sdcard \
     -b /storage/emulated/0 \
     -b /data \
     -b /proc \
     /bin/busybox sh -c "cd /storage/emulated/0; exec /bin/busybox sh -l"
