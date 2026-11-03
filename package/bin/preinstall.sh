#!/system/bin/sh
# Copyright (C) 2026 ntwm787 and contributors
# SPDX-License-Identifier: GPL-3.0-only
export PATH=/data/nemesis/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
export LD_LIBRARY_PATH=/vendor/lib:/system/lib
. ./bin/verify.sh
. ./config.sh
export DST_RULE CHECK
verify_time_service || { echo "$SERVICE_REASON"; exit 1; }
STATE=$(/system/bin/sh ./bin/auto-dst.sh check) || exit 1
echo "$STATE"
case "$STATE" in *'offset= rule='*) echo 'Select a factory Mobis/UTC offset timezone.'; exit 1 ;; esac
case "$STATE" in *'want=0 unit=0'|*'want=0 unit=1'|*'want=1 unit=0'|*'want=1 unit=1') ;; *) echo 'Factory DST state or timezone rule could not be read.'; exit 1 ;; esac
case "$CHECK" in ''|*[!0-9]*|0) echo 'CHECK must be a positive integer.'; exit 1 ;; esac
[ "$CHECK" -gt 0 ] 2>/dev/null || { echo 'CHECK must be positive.'; exit 1; }
echo 'Cabinwright DST port checks passed; no setting changed during preinstall.'
exit 0
