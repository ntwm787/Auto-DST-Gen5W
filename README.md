# Gen5W Auto DST

**Experimental V2 — standalone NEMESIS port of [Cabinwright Tweaks auto-dst](https://github.com/cabinwright/tweaks), by hazptr / Cabinwright.**

The port uses the head unit's selected factory UTC-offset timezone and the upstream US/Canada daylight saving time rule. It is not restricted to Pacific time.

## Installation


1. Park the car. Have a working NEMESIS installation and save a separate copy of existing USB files with the same names.
2. Extract the **outer installer ZIP** directly to USB root.
3. **Keep `packages/gen5w.auto-dst.zip` intact in the supplied `packages` folder.** Do not extract, rename or move the inner ZIP.
4. Follow the NEMESIS USB installation flow and confirm installation/update. The package is named **Gen5W Auto DST**.
5. Keep factory automatic time enabled and choose the factory timezone for your location. Startup waits for the factory time source and for manual time override to be inactive.

The existing internal ID `keybord.dst.ca` and service `keybord.dst.ca/dst` are retained so this installer updates the existing package rather than adding another clock service. That internal ID does not impose a geographic restriction.

## What was ported

`package/bin/auto-dst.sh` preserves Cabinwright's selected-offset calculation, POSIX DST rule, Binder queries/setter, main `summer_time` synchronization, one-minute checks and failure backoff. Its only changes are explicit license/attribution headers and a Gen5W-specific status filename.

Gen5W Auto DST supplies the standalone NEMESIS package, configurable rule/interval, startup and inspected-framework checks. It does not bundle Cabinwright's Tweaks app or other tweaks. It does not replace factory binaries or install an APK.

The service reads `persist.sys.timezone`, converts factory names such as `Mobis/UTC-05:00` or `Mobis/UTC-08:00` to a POSIX offset, and calculates the expected state with `TZ="STD<offset>DST,<rule>" date +%Z`. It calls Hyundai's own DST setter only when expected and actual states differ, updates `Settings.System summer_time`, then checks the factory state again. This port preserves upstream's main-checkbox behavior; it does not add separate Hyundai profile-preference synchronization.

The default rule is `M3.2.0,M11.1.0`: DST starts at 02:00 local standard time on the second Sunday in March and ends at 02:00 local daylight time on the first Sunday in November. It follows the selected offset, so transition instants differ by timezone. It requires no internet for the calculation but does require accurate system time.

A fixed offset cannot identify geographic exceptions. The US/Canada default is for **locations that observe that DST schedule**, not every US/Canadian location or territory. For a location without DST, set `DST_RULE='none'` in `config.sh`; for another schedule, use an appropriate POSIX rule. The package does not infer exemptions from GPS or place names. Other regional schedules are untested.

## Configuration

Installed file: `/data/nemesis/apps/keybord.dst.ca/config.sh`.

```sh
DST_RULE='M3.2.0,M11.1.0'
CHECK=60
```

For no DST, use `DST_RULE='none'`. Configure before installation by editing `package/config.sh` in the source and rebuilding, or edit the installed config and restart the service. Keep `CHECK` a positive integer. `none` directs the service to turn factory DST off; it is not a stop-service option.

## Compatibility and current evidence

Inspected setup: **2023 Hyundai IONIQ 5 SEL**, US Gen5W, Android **4.4.2 / API 19**, head unit **NE1AE.S5BMC.US**, firmware **NEEV23.USA.S5W_M.V015.012.260507**.

Also accepted: firmware **NEEV23.USA.S5W_M.V016.010.260903**, 2023 Hyundai IONIQ 5 Limited AWD (US). Service transactions 3 `isDst` and 4 `setDst` have the same names on this firmware. The package installs there; automatic seasonal switching is not yet confirmed.

The factory Binder interface was independently checked against this vehicle's code. The installer retains checksum checks for the inspected `automotive.odex` and `automotive-service.odex`; matching firmware date text alone is not sufficient. Other factory-framework binaries are rejected. This firmware compatibility check is separate from timezone selection.

**This corrected standalone port has not yet been tested on the vehicle.** Earlier vehicle reports confirmed service installation and readable factory DST state, and a video supported a manual-off correction. Those observations do not establish that this rebuilt port, other timezones, automatic seasonal changes, or restart/resume catch-up work on the vehicle. Host tests exercise the upstream calculation across timezone-specific transitions; they do not validate Android POSIX TZ parsing or service behavior on the head unit.

The service does not wake the car. It is intended to catch up on the next check once the unit is running. Startup and QuickBoot persistence remain to be verified. Automatic operation on a second vehicle must not be claimed from the EV6 reference or matching firmware date alone.

## Stopping and troubleshooting


- **Install refused:** send the exact message. Do not bypass factory-framework or unknown-interface checks.
- **Wrong time or no correction:** check automatic time, selected factory timezone, configured rule and the service log. Do not change the vehicle's date to simulate a transition.
- **Startup wait only:** check the service status; a startup message is not evidence of continued operation.
- **Need manual control:** stop `keybord.dst.ca/dst` or uninstall **Gen5W Auto DST** through NEMESIS. The current factory DST selection stays in place; change it manually afterward if needed.

Service log: `/data/nemesis/logs/keybord.dst.ca/dst.log`.

## Credits and licenses

- **hazptr / Cabinwright:** original Auto DST implementation, [cabinwright/tweaks](https://github.com/cabinwright/tweaks), ported from revision `c593aa1dc115f2596554e94f9a5363052bb29202`.
- **ntwm787 and KeyBORD contributors:** standalone port packaging, startup/interface checks, configuration and diagnostics.
- **xwtk and NEMESIS contributors:** [hmg_nemesis](https://github.com/xwtk/hmg_nemesis), the separately obtained execution and service framework.

The ported `package/bin/auto-dst.sh` retains **MIT**, copyright **2026 hazptr**. Original KeyBORD additions are **GPL-3.0-only**. See [THIRD-PARTY-NOTICES.txt](package/THIRD-PARTY-NOTICES.txt) and [LICENSE.txt](package/LICENSE.txt); both are included in the outer installer and installed package. The combined distribution meets the GPL obligations for KeyBORD additions and preserves the MIT terms for upstream code. Packaging does not erase third-party ownership or license notices.

NEMESIS remains **AGPL-3.0** and is not bundled. No APK, manufacturer code, collected diagnostics, or other Cabinwright tweaks are bundled. Software is provided without warranty under its applicable licenses. This is an independent community project.

## Source, tests and rebuild

From repository root:

```text
python tools/build_auto_dst.py
python tests/test_port.py
```

The build uses Python's standard library and writes the installer under `downloads/`. Tests need a POSIX host shell and GNU date, and never connect to a car. On Windows, set `DST_TEST_SHELL` to Git Bash's executable. Installer and script files use LF line endings.
