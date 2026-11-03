#!/usr/bin/env python3
# Copyright (C) 2026 ntwm787 and contributors
# SPDX-License-Identifier: GPL-3.0-only
"""Host-only tests of the ported upstream functions; never accesses a vehicle."""
import calendar
import datetime as dt
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'package/bin/auto-dst.sh').read_text()
# Source upstream functions without its executable loop. Keep host utilities on PATH.
functions = source.split('# "run.sh check"', 1)[0]
functions = '\n'.join(line for line in functions.splitlines() if not line.startswith('export PATH='))
program = ['set -eu', 'export PATH=/usr/bin:/bin:$PATH', functions, 'getprop() { echo "$TEST_ZONE"; }',
           'date() { /usr/bin/date --date="@$TEST_EPOCH" "$@"; }', 'N=0']
zones = [('Mobis/UTC-04:00', 240), ('Mobis/UTC-05:00', 300),
         ('Mobis/UTC-06:00', 360), ('Mobis/UTC-07:00', 420),
         ('Mobis/UTC-08:00', 480), ('Mobis/UTC-09:00', 540),
         ('Mobis/UTC-03:30', 210)]
for year in (2026, 2027, 2030):
    for zone, west in zones:
        for month, nth, before in ((3, 2, 0), (11, 1, 1)):
            sundays = [d for d in range(1, calendar.monthrange(year, month)[1]+1)
                       if dt.date(year, month, d).weekday() == 6]
            local = dt.datetime(year, month, sundays[nth-1], 2, tzinfo=dt.timezone.utc)
            boundary = local + dt.timedelta(minutes=west - 60 * before)
            for delta in (-3600, -1, 0, 1, 3600):
                stamp = int(boundary.timestamp()) + delta
                expected = int(delta >= 0) if month == 3 else int(delta < 0)
                program += [f'TEST_ZONE={zone}; TEST_EPOCH={stamp}',
                            f'[ "$(should_be_dst)" = {expected} ] || {{ echo "Failed {zone} {year}-{month} delta {delta}"; exit 1; }}',
                            'N=$((N+1))']
program += ["DST_RULE=none; TEST_ZONE=Mobis/UTC-10:00", '[ "$(should_be_dst)" = 0 ]',
            "TEST_ZONE=Mobis/UTC+05:30", '[ "$(base_offset)" = -5:30 ]',
            'DST_RULE=M3.2.0,M11.1.0; TEST_ZONE=America/New_York', '[ -z "$(should_be_dst)" ]',
            'service() { echo "Result: Parcel(00000000 00000001"; }', '[ "$(unit_dst)" = 1 ]',
            'service() { echo "Result: Parcel(00000000 00000000"; }', '[ "$(unit_dst)" = 0 ]',
            'service() { echo "Permission denied"; }', '[ -z "$(unit_dst)" ]',
            'echo "Passed $N timezone-specific transition checks, offset parsing, no-DST configuration and factory-reply parsing."']
program += [(ROOT / 'package/bin/verify.sh').read_text(),
            "service() { if [ \"$1\" = list ]; then echo '48 com.hkmc.micom.time: [com.hkmc.time.ITimePolicyService]'; else echo \"$TEST_REPLY\"; fi; }",
            "TEST_REPLY='Result: Parcel(00000000 00000001'; verify_time_service",
            "TEST_REPLY='Result: Parcel(00000000 00000000'; verify_time_service",
            "TEST_REPLY='Permission denied'; if verify_time_service; then exit 1; fi",
            "TEST_REPLY='Result: Parcel(00000000 00000002'; if verify_time_service; then exit 1; fi",
            "service() { if [ \"$1\" = list ]; then echo '48 com.hkmc.micom.time: [other.interface]'; else echo 'unexpected query'; fi; }",
            "if verify_time_service; then exit 1; fi",
            "service() { return 1; }", "if verify_time_service; then exit 1; fi",
            "echo 'Passed read-only interface guards: valid states, missing/wrong service, denied/unknown replies.'"]
with tempfile.TemporaryDirectory(dir=ROOT / 'tests') as tmp:
    file = Path(tmp) / 'host.sh'
    file.write_text('\n'.join(program)+'\n', newline='\n')
    shell = os.environ.get('DST_TEST_SHELL', 'sh')
    subprocess.run([shell, str(file)], check=True, cwd=ROOT)
