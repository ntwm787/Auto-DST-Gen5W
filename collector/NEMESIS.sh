#!/system/bin/sh
# Copyright (C) 2026 ntwm787 and contributors
# SPDX-License-Identifier: GPL-3.0-only
export PATH=/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
export LD_LIBRARY_PATH=/vendor/lib:/system/lib
umask 077
case "$0" in /*) USB=${0%/*} ;; *) USB=$(pwd) ;; esac
case "$USB" in /storage/usb[0-9]|/mnt/media_rw/usb[0-9]) ;; *) echo 'Run from USB root.'; exit 1 ;; esac
[ -f "$USB/GEN5W-DST-STATUS.marker" ] || exit 1
OUT="$USB/Gen5W-Auto-DST-Status-$(date +%Y%m%d-%H%M%S)-$$"
mkdir "$OUT" || exit 1
{
 echo 'Gen5W Auto DST status v3 - read-only'
 echo '=== Clock ==='
 date
 date -u
 echo "persist.sys.timezone=$(getprop persist.sys.timezone)"
 echo '=== DST preference keys ==='
 for KEY in summer_time summer_time_g summer_time_dr1 summer_time_dr2; do
  echo "$KEY=$(settings get system "$KEY")"
 done
 echo '=== Factory DST query ===' 
 service call com.hkmc.micom.time 3
 echo '=== Selected factory time state (location omitted) ==='
 dumpsys com.hkmc.micom.time | grep -E 'GpsTimeArrived =|NitzTimeArrived =|RealTimeArrived =|userTimeOffset =|isUserTimeSet =|isDST =|TZ =|mIsClockSettingMode =|current user ='
 echo '=== Package registration ==='
 if [ -f /data/nemesis/packages.db ]; then
  grep -F 'gen5w.auto-dst|' /data/nemesis/packages.db
 fi
 echo '=== NEMESIS service status ==='
 if [ -x /data/nemesis/bin/nemesis ]; then
  /data/nemesis/bin/nemesis service status gen5w.auto-dst/dst
 else
  echo 'NEMESIS command not found at /data/nemesis/bin/nemesis.'
 fi
 echo '=== DST service registration ==='
 if [ -f /data/nemesis/services.db ]; then grep -F 'gen5w.auto-dst' /data/nemesis/services.db; fi
 echo '=== Relevant NEMESIS lifecycle log ==='
 if [ -f /data/nemesis/nemesis.log ]; then grep -F 'gen5w.auto-dst' /data/nemesis/nemesis.log; fi
 echo '=== Installed port configuration and read-only check ==='
 BASE=/data/nemesis/apps/gen5w.auto-dst
 if [ -f "$BASE/config.sh" ] && [ -f "$BASE/bin/auto-dst.sh" ]; then
  cat "$BASE/config.sh"
  ( . "$BASE/config.sh"; export DST_RULE CHECK; /system/bin/sh "$BASE/bin/auto-dst.sh" check )
 else
  echo 'Cabinwright standalone port files not present.'
 fi
 echo '=== Auto DST service log ===' 
 if [ -f /data/nemesis/logs/gen5w.auto-dst/dst.log ]; then
  cat /data/nemesis/logs/gen5w.auto-dst/dst.log
 else
  echo 'No service log present.'
 fi
 echo 'End of status report. No setting was changed by this collector.'
} > "$OUT/report.txt" 2>&1 || { echo 'Failed to write report.'; exit 1; }
echo "DST status saved: $OUT"
exit 0
