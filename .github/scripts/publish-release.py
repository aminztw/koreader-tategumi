#!/usr/bin/env python3
"""Resume uploads to a draft and publish only after verifying every asset."""

import json
import os
from pathlib import Path
import subprocess
import sys
import time


def gh(*args, **options):
    return subprocess.run(["gh", *args], text=True, **options)


def release_assets(repo, release_id):
    result = gh(
        "api", "--paginate", f"repos/{repo}/releases/{release_id}/assets?per_page=100",
        "--jq", ".[] | @json", capture_output=True, check=True,
    )
    assets = (json.loads(line) for line in result.stdout.splitlines())
    return {asset["name"]: asset for asset in assets}


def is_uploaded(asset, size):
    return asset is not None and asset["state"] == "uploaded" and asset["size"] == size


def main(tag, directory):
    repo = os.environ["GITHUB_REPOSITORY"]
    files = {}
    for path in sorted(directory.rglob("*")):
        if path.is_file():
            if path.name in files or path.stat().st_size == 0:
                raise SystemExit(f"Duplicate or empty release asset: {path}")
            files[path.name] = path
    if not files:
        raise SystemExit(f"No release assets found in {directory}")

    view_args = ("release", "view", tag, "-R", repo, "--json", "databaseId,isDraft")
    view = gh(*view_args, capture_output=True)
    if view.returncode:
        gh(
            "release", "create", tag, "-R", repo, "--draft", "--verify-tag",
            "--title", f"koreader-tategumi {tag}", "--notes-file", "-",
            input=os.environ["RELEASE_NOTES"], check=True,
        )
        view = gh(*view_args, capture_output=True, check=True)

    release = json.loads(view.stdout)
    release_id = release["databaseId"]
    assets = release_assets(repo, release_id)
    if release["isDraft"]:
        for name, path in files.items():
            size = path.stat().st_size
            for attempt in range(1, 4):
                if is_uploaded(assets.get(name), size):
                    break
                upload = gh("release", "upload", tag, str(path), "-R", repo, "--clobber")
                if upload.returncode == 0:
                    break
                print(f"{name}: upload attempt {attempt} failed", flush=True)
                time.sleep(2 ** attempt)
                assets = release_assets(repo, release_id)
            else:
                if not is_uploaded(assets.get(name), size):
                    raise SystemExit(f"Could not upload {name}. The release remains a draft.")

    assets = release_assets(repo, release_id)
    missing = [name for name, path in files.items()
               if not is_uploaded(assets.get(name), path.stat().st_size)]
    if missing:
        raise SystemExit("Missing or incomplete release assets: " + ", ".join(missing))
    print(f"Verified {len(files)} release assets", flush=True)
    if release["isDraft"]:
        gh("release", "edit", tag, "-R", repo, "--draft=false", check=True)


if __name__ == "__main__":
    main(sys.argv[1], Path(sys.argv[2]))
