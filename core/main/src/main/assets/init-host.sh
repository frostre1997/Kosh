#!/system/bin/sh
export HOME=/storage/emulated/0
export PS1='localhost@hostname:\w# '
cd /storage/emulated/0
exec /bin/busybox sh -l
