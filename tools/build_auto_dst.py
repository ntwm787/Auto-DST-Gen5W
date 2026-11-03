#!/usr/bin/env python3
# Copyright (C) 2026 ntwm787 and contributors
# SPDX-License-Identifier: GPL-3.0-only
"""Build Auto DST USB archives from the repository's script sources."""
from pathlib import Path
from io import BytesIO
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT
OUTPUT = ROOT / 'downloads'


def add(archive, name, data):
    info = ZipInfo(name, date_time=(2026, 11, 2, 0, 0, 0))
    info.compress_type = ZIP_DEFLATED
    info.external_attr = 0o100644 << 16
    archive.writestr(info, data)


def build():
    OUTPUT.mkdir(exist_ok=True)
    docs = (SOURCE / 'README.md').read_bytes()
    notice = (SOURCE / 'package/THIRD-PARTY-NOTICES.txt').read_bytes()
    license_text = (SOURCE / 'package/LICENSE.txt').read_bytes()
    inner = BytesIO()
    with ZipFile(inner, 'w') as archive:
        for file in sorted((SOURCE / 'package').rglob('*')):
            if file.is_file():
                assert file.suffix not in {'.apk', '.odex', '.dex', '.jar'}
                add(archive, file.relative_to(SOURCE / 'package').as_posix(), file.read_bytes())
    package_zip = OUTPUT / 'Gen5W Auto DST V3 Package.zip'
    package_zip.write_bytes(inner.getvalue())
    installer = OUTPUT / 'Gen5W Auto DST V3 USB.zip'
    with ZipFile(installer, 'w') as archive:
        add(archive, 'NEMESIS.data', b'[nemesis]\nversion=1.0\ntype=install\npath=packages/gen5w.auto-dst.zip\n')
        add(archive, 'packages/gen5w.auto-dst.zip', inner.getvalue())
        add(archive, 'README.md', docs)
        add(archive, 'LICENSE.txt', license_text)
        add(archive, 'THIRD-PARTY-NOTICES.txt', notice)
    collector = OUTPUT / 'Gen5W Auto DST Status V3.zip'
    with ZipFile(collector, 'w') as archive:
        for file in sorted((SOURCE / 'collector').iterdir()):
            if file.is_file():
                add(archive, file.name, file.read_bytes())
        add(archive, 'README.md', docs)
    for file in (installer, package_zip, collector):
        with ZipFile(file) as archive:
            assert archive.testzip() is None
        print(file)


if __name__ == '__main__':
    build()
