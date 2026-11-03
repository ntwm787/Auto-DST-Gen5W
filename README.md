# Gen5W Auto DST

**Version 3 — standalone NEMESIS port of [Cabinwright Tweaks auto-dst](https://github.com/cabinwright/tweaks), by hazptr / Cabinwright.**

The port uses the head unit's selected factory UTC-offset timezone and the upstream US/Canada daylight saving time rule. It is not restricted to Pacific time.

## Updated NEMESIS packaging

**Current release: V3.** The V2 ZIP remaining in the repository is a historical archive. Use the V3 release assets for current NEMESIS installations.

V3 uses descriptor format `1.1` with numeric `package-version=3.0.0`, the current `type=service` key, and package-list descriptions. The package uses the geographic-neutral ID `gen5w.auto-dst`. There are no new model, year, firmware or checksum restrictions; the runtime time-service checks remain. DST calculation and factory-setting logic are unchanged.

Use the **USB installer** for the USB-root extraction instructions below. The separate **Package ZIP** contains `NEMESIS.data` directly at archive root for NEMESIS package-import or store workflows; do not extract it onto USB as an execution script. NEMESIS itself is not bundled.

Built against the [current NEMESIS package documentation](https://github.com/xwtk/hmg_nemesis/blob/main/04-Packages.md). This update changes package metadata for the updated NEMESIS format; the working DST calculation and factory-control logic are unchanged.

## Installation

Choose `Gen5W Auto DST V3 USB.zip` for USB-root installation, or `Gen5W Auto DST V3 Package.zip` for direct NEMESIS package import.


1. Park the car. Uninstall any previous Auto DST package through NEMESIS before installing this renamed package. Have a working NEMESIS installation and save a separate copy of existing USB files with the same names.
2. Extract the **outer installer ZIP** directly to USB root.
3. **Keep `packages/gen5w.auto-dst.zip` intact in the supplied `packages` folder.** Do not extract, rename or move the inner ZIP.
4. With the head unit running normally, follow the NEMESIS USB installation flow and confirm installation/update. The installed package appears under **My Packages**. The package is named **Gen5W Auto DST**.
5. Keep factory automatic time enabled and choose the factory timezone for your location. Startup waits for the factory time source and for manual time override to be inactive.

The package ID is `gen5w.auto-dst`, with service `gen5w.auto-dst/dst`. Before installing this renamed package, uninstall the previous Auto DST package through NEMESIS so only one automatic clock service runs. Uninstalling leaves the current factory DST setting in place.

## What was ported

`package/bin/auto-dst.sh` preserves Cabinwright's selected-offset calculation, POSIX DST rule, Binder queries/setter, main `summer_time` synchronization, one-minute checks and failure backoff. Its only changes are explicit license/attribution headers and a Gen5W-specific status filename.

Gen5W Auto DST supplies the standalone NEMESIS package, configurable rule/interval, startup and time-service interface checks. It does not bundle Cabinwright's Tweaks app or other tweaks. It does not replace factory binaries or install an APK.

The service reads `persist.sys.timezone`, converts factory names such as `Mobis/UTC-05:00` or `Mobis/UTC-08:00` to a POSIX offset, and calculates the expected state with `TZ="STD<offset>DST,<rule>" date +%Z`. It calls Hyundai's own DST setter only when expected and actual states differ, updates `Settings.System summer_time`, then checks the factory state again. This port preserves upstream's main-checkbox behavior; it does not add separate Hyundai profile-preference synchronization.

The default rule is `M3.2.0,M11.1.0`: DST starts at 02:00 local standard time on the second Sunday in March and ends at 02:00 local daylight time on the first Sunday in November. It follows the selected offset, so transition instants differ by timezone. It requires no internet for the calculation but does require accurate system time.

A fixed offset cannot identify geographic exceptions. The US/Canada default is for **locations that observe that DST schedule**, not every US/Canadian location or territory. For a location without DST, set `DST_RULE='none'` in `config.sh`; for another schedule, use an appropriate POSIX rule. The package does not infer exemptions from GPS or place names.

## Configuration

Installed file: `/data/nemesis/apps/gen5w.auto-dst/config.sh`.

```sh
DST_RULE='M3.2.0,M11.1.0'
CHECK=60
```

For no DST, use `DST_RULE='none'`. Configure before installation by editing `package/config.sh` in the source and rebuilding, or edit the installed config and restart the service. Keep `CHECK` a positive integer. `none` directs the service to turn factory DST off; it is not a stop-service option.

## Compatibility and current evidence

**Compatibility scope: IONIQ 5 Gen5W units of any model year or trim are eligible when Hyundai's expected time-service interface is available and its read-only DST query returns a recognized state.** No model-year, trim, VIN, firmware-string or factory-file checksum allowlist is enforced. The reference vehicle below identifies the unit used for initial inspection, not an installation requirement.

Inspected setup: **2023 Hyundai IONIQ 5 SEL**, US Gen5W, Android **4.4.2 / API 19**, head unit **NE1AE.S5BMC.US**, firmware **NEEV23.USA.S5W_M.V015.012.260507**.

The factory Binder interface was independently inspected on the reference vehicle. Installation now checks for `com.hkmc.micom.time` with descriptor `com.hkmc.time.ITimePolicyService` and a recognized boolean response to its read-only DST query. It does not read, hash or modify either factory ODEX file. The selected factory timezone and configured rule must also be readable. A successful read establishes eligibility to try the package; it does not prove that the setter or seasonal transition works on every build. Other Gen5W vehicles exposing the same interface may also pass these checks, but are not universally certified compatible.

Tested and reported working by multiple users. The package is not restricted to the reference vehicle or its firmware. Host tests also cover timezone-specific transitions and interface eligibility checks. These reports do not establish compatibility with every Gen5W build.

The service does not wake the car. It checks again once the head unit is running and the factory time source is ready. Compatibility is checked through the available time-service interface rather than a firmware or model-year allowlist.

## Stopping and troubleshooting


- **Install refused:** send the exact message. The required time service, its readable state, selected timezone or configuration may be unavailable; include the exact failure text.
- **Wrong time or no correction:** check automatic time, selected factory timezone, configured rule and the service log. Do not change the vehicle's date to simulate a transition.
- **Startup wait only:** check the service status; a startup message is not evidence of continued operation.
- **Need manual control:** stop `gen5w.auto-dst/dst` or uninstall **Gen5W Auto DST** through NEMESIS. The current factory DST selection stays in place; change it manually afterward if needed.

Service log: `/data/nemesis/logs/gen5w.auto-dst/dst.log`.

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
