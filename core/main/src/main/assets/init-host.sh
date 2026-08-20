#!/system/bin/sh

# ─── Setup prompt, storage commands, and copy pkg ────────────────
if [ ! -f /root/.profile ]; then
    # Use the real storage path (not symlink)
    echo "export HOME=/storage/emulated/0" > /root/.profile
    echo "export PS1='localhost@hostname:\\w# '" >> /root/.profile

    # ─── Create bin directory ──────────────────────────────────────
    mkdir -p /root/bin

    # ─── Copy `pkg` from assets (if available) ────────────────────
    if [ -f /data/data/com.kosh.shell/files/pkg.sh ]; then
        cp /data/data/com.kosh.shell/files/pkg.sh /root/bin/pkg
        chmod +x /root/bin/pkg
    else
        # Fallback: warn user
        cat > /root/bin/pkg << 'FALLBACK'
#!/system/bin/sh
echo "pkg: asset not found. Please ensure pkg.sh is bundled."
FALLBACK
        chmod +x /root/bin/pkg
    fi

    # ─── Create `storageinfo` command ──────────────────────────────
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
    echo "  No sdcard found."
fi
SCRIPT
    chmod +x /root/bin/storageinfo

    # ─── Create `storage` command (quick free space) ──────────────
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
    echo "No sdcard found."
fi
SCRIPT
    chmod +x /root/bin/storage

    # Add /root/bin to PATH
    echo 'export PATH="/root/bin:$PATH"' >> /root/.profile
fi

# ─── Proot command ──────────────────────────────────────────────────
# Force start in /storage/emulated/0 using -w and -c with cd
proot -r "$ALPINE_ROOT" \
     -b /sdcard \
     -b /storage/emulated/0 \
     -b /data \
     -b /proc \
     /bin/busybox sh -c "cd /storage/emulated/0; exec /bin/busybox sh -l"
