#!/system/bin/sh
# Copyright (C) 2026 ntwm787 and contributors
# SPDX-License-Identifier: GPL-3.0-only
# Read-only interface eligibility check, not a setter compatibility proof.
verify_time_service() {
 SERVICE_REASON=
 if ! service list 2>/dev/null | grep -F 'com.hkmc.micom.time: [com.hkmc.time.ITimePolicyService]' >/dev/null; then
  SERVICE_REASON='Hyundai time-service interface is unavailable or different.'
  return 1
 fi
 DST_REPLY=$(service call com.hkmc.micom.time 3 2>/dev/null) || {
  SERVICE_REASON='Factory DST state could not be queried.'
  return 1
 }
 case "$DST_REPLY" in
  "Result: Parcel(00000000 00000000"*|"Result: Parcel(00000000 00000001"*) return 0 ;;
  *) SERVICE_REASON='Factory DST query returned an unrecognized reply.'; return 1 ;;
 esac
}
