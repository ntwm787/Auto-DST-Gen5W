#!/system/bin/sh
# Copyright (C) 2026 ntwm787 and contributors
# SPDX-License-Identifier: GPL-3.0-only
export PATH=/data/nemesis/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
export LD_LIBRARY_PATH=/vendor/lib:/system/lib
BASE=/data/nemesis/apps/gen5w.auto-dst
. "$BASE/bin/verify.sh"
. "$BASE/config.sh"
export DST_RULE CHECK
echo 'Gen5W Auto DST V3 - Cabinwright standalone port.'
LAST=
while :; do
 REASON=
 if ! verify_time_service; then
  REASON="Waiting: $SERVICE_REASON"
 else
  REPORT=$(dumpsys com.hkmc.micom.time 2>/dev/null)
  if ! echo "$REPORT" | grep -F 'RealTimeArrived = true' >/dev/null; then
   REASON='Waiting: factory time source is not ready.'
  elif ! echo "$REPORT" | grep -F 'isUserTimeSet = false' >/dev/null; then
   REASON='Waiting: manual time override is active or unknown.'
  fi
  unset REPORT
 fi
 if [ -z "$REASON" ]; then
  # The upstream script owns all timezone/rule/state decisions from here.
  exec /system/bin/sh "$BASE/bin/auto-dst.sh"
 fi
 if [ "$REASON" != "$LAST" ]; then echo "$(date) $REASON"; LAST=$REASON; fi
 sleep 5
done
