#!/usr/bin/env python3
import glob
import hashlib
import json
import os
import re
import subprocess
import sys


def md5_file(filepath):
    if not os.path.isfile(filepath):
        return None
    hasher = hashlib.md5()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def download_via_gh_release(repo, tag, asset_name, dest):
    # Try 1: gh release download (uses GitHub REST API asset endpoint)
    cmd = [
        "gh",
        "release",
        "download",
        tag,
        "--repo",
        repo,
        "-p",
        asset_name,
        "-O",
        dest,
        "--clobber",
    ]
    res = subprocess.run(cmd)
    if res.returncode == 0 and os.path.isfile(dest):
        return True

    # Try 2: Direct gh api call to asset endpoint with Accept: application/octet-stream
    meta_cmd = ["gh", "api", f"repos/{repo}/releases/tags/{tag}"]
    meta_res = subprocess.run(meta_cmd, capture_output=True, text=True)
    if meta_res.returncode == 0:
        try:
            data = json.loads(meta_res.stdout)
            for asset in data.get("assets", []):
                if asset.get("name") == asset_name:
                    api_url = asset.get("url")
                    if api_url:
                        with open(dest, "wb") as out_f:
                            dl_res = subprocess.run(
                                [
                                    "gh",
                                    "api",
                                    "-H",
                                    "Accept: application/octet-stream",
                                    api_url,
                                ],
                                stdout=out_f,
                            )
                        if dl_res.returncode == 0 and os.path.isfile(dest):
                            return True
        except Exception as e:
            print(f"Warning: gh api asset fallback error: {e}")
    return False


def main():
    pattern = re.compile(r"DOWNLOAD\s+URL\s+([0-9a-fA-F]{32})\s+([^\s\)]+)")
    gh_release_pattern = re.compile(
        r"^https://github\.com/([^/]+/[^/]+)/releases/download/([^/]+)/(.+)$"
    )
    packages = []

    for cmake in sorted(glob.glob("base/thirdparty/*/CMakeLists.txt")):
        with open(cmake) as f:
            content = f.read()
        for md5, url in pattern.findall(content):
            pkg = cmake.split("/")[2]
            filename = url.split("/")[-1]
            dest = f"base/thirdparty/{pkg}/build/downloads/{filename}"
            packages.append((pkg, url, dest, md5))

    print(
        f"Found {len(packages)} thirdparty archives to verify/download.",
        flush=True,
    )

    failed = []
    for pkg, url, dest, expected_md5 in packages:
        if os.path.isfile(dest):
            actual = md5_file(dest)
            if actual == expected_md5:
                print(
                    f"[{pkg}] {os.path.basename(dest)} already downloaded and verified.",
                    flush=True,
                )
                continue
            else:
                print(
                    f"[{pkg}] MD5 mismatch for existing {dest} ({actual} vs {expected_md5}), re-downloading...",
                    flush=True,
                )
                os.remove(dest)

        os.makedirs(os.path.dirname(dest), exist_ok=True)
        print(f"[{pkg}] Downloading {url} ...", flush=True)

        # For GitHub Release assets, prefer authenticated GitHub API via `gh`
        # to avoid web controller 504 Gateway Timeouts.
        m = gh_release_pattern.match(url)
        if m:
            repo, tag, asset_name = m.groups()
            if download_via_gh_release(repo, tag, asset_name, dest):
                if md5_file(dest) == expected_md5:
                    print(
                        f"[{pkg}] OK (via GitHub API): {os.path.basename(dest)}",
                        flush=True,
                    )
                    continue
                else:
                    print(
                        f"[{pkg}] MD5 mismatch from gh release download, falling back to curl...",
                        flush=True,
                    )

        cmd = [
            "curl",
            "-4",
            "-fSL",
            "--connect-timeout",
            "30",
            "--max-time",
            "300",
            "--retry",
            "3",
            "--retry-delay",
            "2",
            "-o",
            dest,
            url,
        ]
        res = subprocess.run(cmd)
        if res.returncode == 0 and md5_file(dest) == expected_md5:
            print(f"[{pkg}] OK: {os.path.basename(dest)}", flush=True)
        else:
            print(
                f"[{pkg}] ERROR: Download failed or MD5 mismatch!", flush=True
            )
            failed.append((pkg, url))

    if failed:
        print(
            f"\nERROR: {len(failed)} package(s) failed to download:",
            flush=True,
        )
        for pkg, url in failed:
            print(f"  {pkg}: {url}", flush=True)
        sys.exit(1)
    else:
        print(
            "\nAll 37 thirdparty packages downloaded and verified successfully!",
            flush=True,
        )


if __name__ == "__main__":
    main()
