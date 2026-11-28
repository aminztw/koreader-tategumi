#!/usr/bin/env python3
"""Verify that release installers contain the fork's Traditional Chinese catalog."""

import subprocess
import sys
import tempfile
from pathlib import Path
from zipfile import ZipFile

CATALOG = "l10n/zh_TW/koreader.mo"
EXPECTED = Path("l10n_custom/zh_TW/koreader.mo").read_bytes()


def read_catalog(package):
    with ZipFile(package) as archive:
        if package.suffix == ".zip":
            catalogs = [
                entry for entry in archive.namelist()
                if entry == CATALOG or entry.endswith("/" + CATALOG)
            ]
            if len(catalogs) != 1:
                raise SystemExit(f"{package}: expected exactly one Traditional Chinese catalog")
            return archive.read(catalogs[0])

        with tempfile.TemporaryDirectory() as directory:
            nested = archive.extract("assets/module/koreader.7z", directory)
            return subprocess.check_output(["7z", "x", "-so", nested, CATALOG])


if len(sys.argv) == 1:
    raise SystemExit("Provide at least one release ZIP or APK to verify.")

for argument in sys.argv[1:]:
    package = Path(argument)
    if read_catalog(package) != EXPECTED:
        raise SystemExit(f"{package}: incorrect Traditional Chinese catalog")
    print(f"{package}: Traditional Chinese catalog verified")
