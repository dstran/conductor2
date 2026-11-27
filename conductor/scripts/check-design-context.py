#!/usr/bin/env python3
"""Read-only check that approved design inputs can follow a track's Git HEAD."""

import argparse
from pathlib import Path
import subprocess
import sys


def git(root, *args):
    return subprocess.run(
        ["git", "--literal-pathspecs", "-C", str(root), *args],
        check=True, capture_output=True, text=True,
    ).stdout.strip()


def check_file(root, name):
    relative = Path(name)
    if relative.is_absolute() or ".." in relative.parts or not relative.parts:
        raise ValueError(f"expected an explicit project-relative file: {name!r}")
    parts = relative.parts
    if any(
        part in (".git", ".worktrees", ".superpowers", ".ssh", ".aws")
        or part == ".env" or part.startswith(".env.")
        for part in parts
    ):
        raise ValueError(f"private or runtime record is not a handoff input: {name!r}")
    if ".impeccable" in parts:
        suffix = Path(*parts[parts.index(".impeccable") + 1:]).as_posix()
        durable = {
            "config.json", "design.json", "live/config.json", "critique/ignore.md",
        }
        if suffix not in durable and not suffix.startswith(("surfaces/", "reference/")):
            raise ValueError(f"private or runtime record is not a handoff input: {name!r}")

    target = root
    for part in parts:
        target = target / part
        if target.is_symlink():
            raise ValueError(f"symlink is not a portable handoff input: {name!r}")
    if not target.is_file():
        raise ValueError(f"not a regular file: {name!r}")

    path = relative.as_posix()
    try:
        committed = git(root, "rev-parse", "--verify", f"HEAD:{path}")
        staged = git(root, "rev-parse", "--verify", f":{path}")
        # Hash without -w: no object writes. Git's path filters account for
        # normal checkout transformations such as CRLF, while still detecting
        # changes hidden from diff by assume-unchanged/skip-worktree flags.
        working = git(root, "hash-object", f"--path={path}", "--", path)
    except subprocess.CalledProcessError:
        raise ValueError(f"not committed unchanged at HEAD: {name!r}") from None
    if committed != staged or committed != working:
        raise ValueError(f"not committed unchanged at HEAD: {name!r}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+", help="explicit approved repository-relative files")
    args = parser.parse_args()
    try:
        root = Path(git(Path.cwd(), "rev-parse", "--show-toplevel")).resolve()
        for name in args.paths:
            check_file(root, name)
        head = git(root, "rev-parse", "HEAD")
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        if isinstance(error, subprocess.CalledProcessError):
            print("STOP: cannot verify design context in this Git worktree.", file=sys.stderr)
        else:
            print(f"STOP: {error}", file=sys.stderr)
        return 1
    print(f"PASS: {len(args.paths)} approved context file(s) committed unchanged at {head}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
