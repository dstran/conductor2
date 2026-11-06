#!/usr/bin/env python3
"""Safely resume the archive cleanup phase for one Conductor track."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import NoReturn


ARCHIVE_MESSAGE = "chore(conductor): Archive track '{track_id}'"
AWAITING_REVIEW_NOTE = "Status: implementation complete — awaiting review."
TRACK_ID_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_-]*$")
SHA_PATTERN = re.compile(r"^[0-9a-fA-F]{7,64}$")
TASK_PATTERN = re.compile(
    r"^\s*-\s*\[x\]\s+Task:.*\[[A-Za-z0-9_-]+\]\s+[0-9a-fA-F]{7,64}\s*$"
)
TASK_LINE_PATTERN = re.compile(r"^\s*-\s*\[([ x~])\]\s+Task:")
CHECKPOINT_PATTERN = re.compile(
    r"\[checkpoint:\s*([0-9a-fA-F]{7,64})\]"
)


class ArchiveError(Exception):
    """A user-actionable archive preflight or mutation failure."""


def stop(message: str) -> NoReturn:
    raise ArchiveError(message)


def git(repo: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if check and result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        stop(f"git {' '.join(args)} failed: {detail}")
    return result.stdout.strip()


def git_bytes(repo: Path, *args: str, check: bool = True) -> bytes:
    result = subprocess.run(
        ["git", *args],
        cwd=repo,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if check and result.returncode != 0:
        detail = (result.stderr or result.stdout).decode(errors="replace").strip()
        stop(f"git {' '.join(args)} failed: {detail}")
    return result.stdout


def repo_root() -> Path:
    try:
        return Path(git(Path.cwd(), "rev-parse", "--show-toplevel")).resolve()
    except ArchiveError as error:
        stop(f"not inside a Git repository: {error}")


def current_branch(repo: Path) -> str:
    branch = git(repo, "symbolic-ref", "--quiet", "--short", "HEAD", check=False)
    if not branch:
        stop("repository is in detached HEAD state")
    return branch


def ensure_track_id(track_id: str) -> None:
    if (
        not TRACK_ID_PATTERN.fullmatch(track_id)
        or track_id in {".", ".."}
        or "/" in track_id
        or "\\" in track_id
    ):
        stop(f"invalid track_id: {track_id!r}")


def ensure_no_symlink(path: Path, repo: Path, label: str) -> None:
    relative = path.relative_to(repo)
    current = repo
    for part in relative.parts:
        current /= part
        if current.is_symlink():
            stop(f"{label} contains symlinked path component: {current}")


def ensure_under_repo(path: Path, repo: Path, label: str) -> None:
    try:
        path.resolve(strict=False).relative_to(repo.resolve())
    except ValueError:
        stop(f"{label} resolves outside the repository: {path}")


def require_file(path: Path, repo: Path, label: str) -> None:
    ensure_no_symlink(path, repo, label)
    ensure_under_repo(path, repo, label)
    if not path.is_file():
        stop(f"missing {label}: {path}")


def require_directory(path: Path, repo: Path, label: str) -> None:
    ensure_no_symlink(path, repo, label)
    ensure_under_repo(path, repo, label)
    if not path.is_dir():
        stop(f"missing {label} directory: {path}")


def read_json(path: Path, repo: Path) -> dict:
    require_file(path, repo, "metadata.json")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        stop(f"metadata.json is not valid JSON: {error}")
    if not isinstance(value, dict):
        stop("metadata.json must contain a JSON object")
    return value


def parse_rfc3339_utc(value: object, field: str) -> None:
    if not isinstance(value, str) or not re.fullmatch(
        r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z", value
    ):
        stop(f"metadata {field} must be an RFC 3339 UTC timestamp")
    try:
        datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ")
    except ValueError as error:
        stop(f"metadata {field} is invalid: {error}")


def load_metadata(repo: Path, source: Path, track_id: str, branch: str) -> tuple[dict, str]:
    path = source / "metadata.json"
    metadata = read_json(path, repo)
    required = ("id", "type", "status", "branch", "created", "updatedAt")
    missing = [field for field in required if field not in metadata]
    if missing:
        stop(f"metadata.json is missing required fields: {', '.join(missing)}")
    if metadata.get("id") != track_id:
        stop("metadata id does not match track_id")
    if not isinstance(metadata.get("type"), str) or not metadata["type"].strip():
        stop("metadata type must be a non-empty string")
    if not isinstance(metadata.get("status"), str):
        stop("metadata status must be a string")
    if not isinstance(metadata.get("branch"), str):
        stop("metadata branch must be a string")
    if metadata["branch"] != branch:
        stop("metadata branch does not match the current branch")
    expected_branch = f"track/{track_id}"
    if branch != expected_branch:
        stop(
            f"archive must run from the track worktree branch {expected_branch!r}; "
            f"observed {branch!r}"
        )
    worktree_path = metadata.get("worktreePath")
    if worktree_path is not None and not isinstance(worktree_path, str):
        stop("metadata worktreePath must be a string when present")
    for field in ("created", "updatedAt"):
        parse_rfc3339_utc(metadata[field], field)
    for field in ("baseBranch", "baseRef"):
        if field in metadata and not isinstance(metadata[field], str):
            stop(f"metadata {field} must be a string when present")
    if "baseRef" in metadata and not SHA_PATTERN.fullmatch(metadata["baseRef"]):
        stop("metadata baseRef must be a hexadecimal commit SHA when present")
    return metadata, path.read_text(encoding="utf-8")


def verify_worktree_path(repo: Path, metadata: dict) -> None:
    recorded = metadata.get("worktreePath")
    if not recorded:
        return
    common_git = Path(git(repo, "rev-parse", "--path-format=absolute", "--git-common-dir"))
    main_root = common_git.parent if common_git.name == ".git" else common_git
    expected = Path(recorded)
    if not expected.is_absolute():
        expected = main_root / expected
    if expected.resolve() != repo.resolve():
        stop(f"current worktree does not match metadata worktreePath: {recorded}")


def load_registry(repo: Path, track_id: str) -> tuple[Path, str, list[str], int, int, str]:
    path = repo / "conductor" / "tracks.md"
    require_file(path, repo, "tracks registry")
    original = path.read_text(encoding="utf-8")
    lines = original.splitlines(keepends=True)
    link = f"tracks/{track_id}/plan.md"
    matches = [index for index, line in enumerate(lines) if link in line]
    if len(matches) != 1:
        stop(f"expected exactly one registry entry for {track_id}, found {len(matches)}")
    entry = matches[0]
    section = ""
    for line in lines[: entry + 1]:
        if line.startswith("## "):
            section = line.strip()
    note_end = entry + 1
    if note_end < len(lines) and lines[note_end].strip().startswith(("Status:", "Blocker:")):
        note_end += 1
    for index, line in enumerate(lines):
        if not line.strip().startswith(("Status:", "Blocker:")):
            continue
        if index == 0 or not re.match(r"^\s*-\s*\[[^]]+\]", lines[index - 1]):
            stop(f"registry contains an orphan lifecycle note at line {index + 1}")
    return path, original, lines, entry, note_end, section


def validate_registry(
    lines: list[str], entry: int, note_end: int, section: str, status: str
) -> None:
    line = lines[entry]
    if status == "complete":
        if note_end > entry + 1:
            stop("complete metadata has an orphan lifecycle note in its registry block")
        if section != "## Active" or not re.search(r"^\s*-\s*\[x\]", line):
            stop("complete metadata requires a completed [x] entry under ## Active")
    elif status == "awaiting-review":
        note = lines[entry + 1].strip() if note_end > entry + 1 else ""
        if (
            section != "## Active"
            or not re.search(r"^\s*-\s*\[~\]", line)
            or note != AWAITING_REVIEW_NOTE
        ):
            stop("awaiting-review metadata requires the documented [~] registry block")
    else:
        stop(f"unsupported lifecycle status for archive: {status!r}")


def validate_no_other_live_tracks(lines: list[str], entry: int) -> None:
    section = ""
    for index, line in enumerate(lines):
        if line.startswith("## "):
            section = line.strip()
        if (
            index == entry
            or section not in {"## Active", "## Blocked"}
            or "tracks/" not in line
            or "/plan.md" not in line
        ):
            continue
        stop("another live track remains in the registry; shared-branch cleanup is blocked")


def validate_plan(path: Path, repo: Path) -> None:
    require_file(path, repo, "plan.md")
    lines = path.read_text(encoding="utf-8").splitlines()
    task_lines = [line for line in lines if TASK_LINE_PATTERN.match(line)]
    if not task_lines:
        stop("plan.md contains no task lines")
    for line in task_lines:
        if not TASK_PATTERN.match(line):
            stop(f"plan task is not terminal with a commit SHA: {line.strip()}")
    for line in lines:
        if "[checkpoint:" in line and not CHECKPOINT_PATTERN.search(line):
            stop(f"phase checkpoint is malformed: {line.strip()}")


def resolve_upstream(repo: Path, branch: str) -> tuple[str, str, str]:
    upstream = git(
        repo,
        "rev-parse",
        "--abbrev-ref",
        "--symbolic-full-name",
        "@{upstream}",
        check=False,
    )
    if not upstream or "/" not in upstream:
        stop("current branch has no configured remote tracking branch")
    remote, remote_branch = upstream.split("/", 1)
    if remote_branch != branch:
        stop("configured upstream branch does not match metadata branch")
    remote_ref = f"refs/remotes/{remote}/{remote_branch}"
    return remote, remote_branch, remote_ref


def fetch_upstream(repo: Path, remote: str, branch: str) -> None:
    result = subprocess.run(
        ["git", "fetch", "--quiet", remote, branch],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        stop(f"could not fetch remote branch {remote}/{branch}: {detail}")


def ancestry(repo: Path, ancestor: str, descendant: str) -> bool:
    return subprocess.run(
        ["git", "merge-base", "--is-ancestor", ancestor, descendant],
        cwd=repo,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    ).returncode == 0


def branch_state(repo: Path, remote_ref: str) -> tuple[str, str]:
    local = git(repo, "rev-parse", "HEAD")
    remote = git(repo, "rev-parse", "--verify", remote_ref)
    if local == remote:
        return "equal", local
    if ancestry(repo, remote, local):
        return "local-ahead", local
    if ancestry(repo, local, remote):
        return "remote-ahead", local
    return "diverged", local


def branch_ref(repo: Path) -> str:
    ref = git(repo, "symbolic-ref", "--quiet", "HEAD", check=False)
    if not ref:
        stop("repository is in detached HEAD state")
    return ref


def require_current_revision(state: dict, expected_head: str | None = None) -> None:
    repo = state["repo"]
    observed_branch = current_branch(repo)
    observed_ref = branch_ref(repo)
    observed_head = git(repo, "rev-parse", "HEAD")
    expected = expected_head or state["original_head"]
    if observed_branch != state["branch"] or observed_ref != state["head_ref"]:
        stop("current branch changed after archive verification")
    if observed_head != expected:
        stop(
            f"current HEAD changed after archive verification: "
            f"expected {expected}, observed {observed_head}"
        )
    clean = git(repo, "status", "--porcelain=v1", "--untracked-files=all")
    if clean:
        stop(f"working tree changed after archive verification: {clean.replace(chr(10), '; ')}")


def now_utc() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def write_metadata(path: Path, metadata: dict) -> None:
    metadata["status"] = "archived"
    metadata["updatedAt"] = now_utc()
    path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")


def staged_paths(repo: Path) -> list[str]:
    data = git_bytes(repo, "diff", "--cached", "--name-only", "-z")
    return [item.decode() for item in data.split(b"\0") if item]


def verify_staged_paths(repo: Path, track_id: str) -> None:
    allowed_registry = "conductor/tracks.md"
    allowed_prefixes = (
        f"conductor/tracks/{track_id}/",
        f"conductor/archive/{track_id}/",
    )
    paths = staged_paths(repo)
    if not paths:
        stop("archive mutation produced no staged paths")
    unexpected = [
        path
        for path in paths
        if path != allowed_registry and not path.startswith(allowed_prefixes)
    ]
    if unexpected:
        stop(f"staged diff contains unrelated paths: {', '.join(unexpected)}")


def verify_commit_paths(repo: Path, track_id: str, commit: str) -> None:
    changed = git(repo, "diff-tree", "--no-commit-id", "--name-only", "-r", commit)
    allowed_prefixes = (
        "conductor/tracks.md",
        f"conductor/tracks/{track_id}/",
        f"conductor/archive/{track_id}/",
    )
    paths = [path for path in changed.splitlines() if path]
    unexpected = [
        path
        for path in paths
        if path != allowed_prefixes[0]
        and not path.startswith(allowed_prefixes[1])
        and not path.startswith(allowed_prefixes[2])
    ]
    if not paths:
        stop("archive commit contains no changed paths")
    if unexpected:
        stop(f"archive commit contains unexpected paths: {', '.join(unexpected)}")


def verify_archive_commit(repo: Path, track_id: str, branch: str) -> str:
    source = repo / "conductor" / "tracks" / track_id
    destination = repo / "conductor" / "archive" / track_id
    registry = repo / "conductor" / "tracks.md"
    if source.exists():
        stop("source track folder still exists after archive commit")
    if not destination.is_dir():
        stop("archive destination is missing after archive commit")
    if f"tracks/{track_id}/plan.md" in registry.read_text(encoding="utf-8"):
        stop("registry entry still exists after archive commit")
    commit = git(repo, "rev-parse", "HEAD")
    message = git(repo, "log", "-1", "--format=%s")
    if message != ARCHIVE_MESSAGE.format(track_id=track_id):
        stop("archive commit message is incorrect")
    verify_commit_paths(repo, track_id, commit)
    return commit


def verify_resume_state(args: argparse.Namespace) -> dict:
    track_id = args.track_id
    ensure_track_id(track_id)
    repo = repo_root()
    branch = current_branch(repo)
    source = repo / "conductor" / "tracks" / track_id
    archive = repo / "conductor" / "archive" / track_id
    require_directory(archive, repo, "archive destination")
    ensure_no_symlink(source, repo, "source track directory")
    if source.exists():
        stop("--resume-push requires the source track directory to be absent")
    metadata, _ = load_metadata(repo, archive, track_id, branch)
    if metadata.get("status") != "archived":
        stop("--resume-push requires archived metadata status")
    registry = repo / "conductor" / "tracks.md"
    require_file(registry, repo, "tracks registry")
    if f"tracks/{track_id}/plan.md" in registry.read_text(encoding="utf-8"):
        stop("--resume-push requires the registry entry to be absent")
    clean = git(repo, "status", "--porcelain=v1", "--untracked-files=all")
    if clean:
        stop(f"working tree is dirty: {clean.replace(chr(10), '; ')}")
    remote, remote_branch, remote_ref = resolve_upstream(repo, branch)
    commit = git(repo, "rev-parse", "HEAD")
    if git(repo, "log", "-1", "--format=%s") != ARCHIVE_MESSAGE.format(track_id=track_id):
        stop("latest local commit is not the expected archive commit")
    verify_commit_paths(repo, track_id, commit)
    return {
        "repo": repo,
        "track_id": track_id,
        "branch": branch,
        "remote": remote,
        "remote_branch": remote_branch,
        "remote_ref": remote_ref,
        "commit": commit,
        "original_head": commit,
        "head_ref": branch_ref(repo),
    }


def resume_push(args: argparse.Namespace) -> int:
    ensure_track_id(args.track_id)
    repo = repo_root()
    with archive_lock(repo, args.track_id):
        state = verify_resume_state(args)
        repo = state["repo"]
        fetch_upstream(repo, state["remote"], state["remote_branch"])
        require_current_revision(state)
        remote_tip = git(repo, "rev-parse", "--verify", state["remote_ref"])
        local_tip = state["commit"]
        if remote_tip != local_tip and not ancestry(repo, remote_tip, local_tip):
            if ancestry(repo, local_tip, remote_tip):
                print(f"ARCHIVE ALREADY PUSHED: {local_tip}")
                return 0
            stop("remote branch diverged from the local archive commit")
        if remote_tip != local_tip:
            push = subprocess.run(
                ["git", "push", state["remote"], f"{local_tip}:{state['remote_branch']}"],
                cwd=repo,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            if push.returncode != 0:
                stop(f"archive resume push failed: {push.stderr.strip() or push.stdout.strip()}")
        fetch_upstream(repo, state["remote"], state["remote_branch"])
        remote_tip = git(repo, "rev-parse", "--verify", state["remote_ref"])
        if not ancestry(repo, local_tip, remote_tip):
            stop("remote branch does not contain the archive commit after resume push")
        print(f"ARCHIVED: {state['track_id']}")
        print(f"COMMIT: {local_tip}")
        return 0


@contextmanager
def archive_lock(repo: Path, track_id: str):
    common_git = Path(git(repo, "rev-parse", "--path-format=absolute", "--git-common-dir"))
    lock = common_git / f"conductor-archive-{track_id}.lock"
    try:
        lock.mkdir()
    except FileExistsError:
        stop(f"another archive operation is already running: {lock}")
    try:
        yield
    finally:
        shutil.rmtree(lock, ignore_errors=True)


def prompt_confirmation(track_id: str) -> None:
    answer = input(f"Archive track '{track_id}' and push the result? [y/N] ").strip().lower()
    if answer not in {"y", "yes"}:
        stop("user declined archive operation")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="archive-track.py")
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--apply", action="store_true")
    modes.add_argument("--dry-run", action="store_true")
    modes.add_argument("--resume-push", action="store_true")
    parser.add_argument("track_id")
    return parser.parse_args()


def preflight(args: argparse.Namespace) -> dict:
    track_id = args.track_id
    ensure_track_id(track_id)
    repo = repo_root()
    branch = current_branch(repo)
    source = repo / "conductor" / "tracks" / track_id
    archive_root = repo / "conductor" / "archive"
    destination = archive_root / track_id
    require_directory(source, repo, "track")
    ensure_no_symlink(archive_root, repo, "archive directory")
    ensure_under_repo(destination, repo, "archive destination")
    ensure_no_symlink(destination, repo, "archive destination")
    if args.resume_push:
        stop("--resume-push is not available until an archive commit exists")
    metadata, metadata_text = load_metadata(repo, source, track_id, branch)
    verify_worktree_path(repo, metadata)
    status = metadata.get("status")
    if status in {"in-progress", "blocked"}:
        stop(f"metadata status {status!r} is a hard stop")
    if status not in {"complete", "awaiting-review"}:
        stop(f"metadata status is not eligible for archive: {status!r}")
    registry_path, registry_text, registry_lines, entry, note_end, section = load_registry(repo, track_id)
    validate_registry(registry_lines, entry, note_end, section, status)
    validate_no_other_live_tracks(registry_lines, entry)
    if destination.exists():
        stop(f"archive destination already exists: {destination}")
    for name in ("plan.md", "spec.md", "review.md"):
        require_file(source / name, repo, name)
    validate_plan(source / "plan.md", repo)
    clean = git(repo, "status", "--porcelain=v1", "--untracked-files=all")
    if clean:
        stop(f"working tree is dirty: {clean.replace(chr(10), '; ')}")
    remote, remote_branch, remote_ref = resolve_upstream(repo, branch)
    return {
        "repo": repo,
        "track_id": track_id,
        "branch": branch,
        "source": source,
        "archive_root": archive_root,
        "destination": destination,
        "metadata": metadata,
        "metadata_text": metadata_text,
        "registry_path": registry_path,
        "registry_text": registry_text,
        "registry_lines": registry_lines,
        "entry": entry,
        "note_end": note_end,
        "remote": remote,
        "remote_branch": remote_branch,
        "remote_ref": remote_ref,
        "original_head": git(repo, "rev-parse", "HEAD"),
        "head_ref": branch_ref(repo),
    }


def registry_without_block(lines: list[str], entry: int, note_end: int) -> str:
    result = lines[:entry] + lines[note_end:]
    return "".join(result)


def rollback(
    state: dict,
    registry_text: str,
    metadata_text: str,
    archive_root_created: bool,
) -> None:
    repo = state["repo"]
    source = state["source"]
    destination = state["destination"]
    try:
        current_ref = branch_ref(repo)
        current_head = git(repo, "rev-parse", "HEAD")
        archive_commit = state.get("archive_commit")
        if current_ref != state["head_ref"]:
            stop("rollback refused because the current branch reference changed")
        if archive_commit:
            if current_head != archive_commit:
                stop("rollback refused because the archive commit is no longer HEAD")
            result = subprocess.run(
                ["git", "update-ref", state["head_ref"], state["original_head"], archive_commit],
                cwd=repo,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            if result.returncode != 0:
                stop(
                    "rollback could not move the branch back: "
                    f"{result.stderr.strip() or result.stdout.strip()}"
                )
        elif current_head != state["original_head"]:
            stop("rollback refused because HEAD changed before the archive commit")

        ensure_no_symlink(destination, repo, "archive destination during rollback")
        if destination.exists() and not source.exists():
            shutil.move(str(destination), str(source))
        if archive_root_created and state["archive_root"].is_dir() and not any(state["archive_root"].iterdir()):
            state["archive_root"].rmdir()
        git(repo, "read-tree", state["original_head"])
        git(repo, "restore", "--source", state["original_head"], "--worktree", "--", ".")
        if registry_text != state["registry_path"].read_text(encoding="utf-8"):
            state["registry_path"].write_text(registry_text, encoding="utf-8")
        restored_metadata = source / "metadata.json"
        if metadata_text != restored_metadata.read_text(encoding="utf-8"):
            restored_metadata.write_text(metadata_text, encoding="utf-8")
        remaining = git(repo, "status", "--porcelain=v1", "--untracked-files=all")
        if remaining:
            stop(f"rollback left recoverable working-tree changes: {remaining.replace(chr(10), '; ')}")
    except Exception as error:  # pragma: no cover - last-resort diagnostic path
        stop(f"rollback could not be proven complete: {error}")


def mutate_and_push(state: dict) -> int:
    repo = state["repo"]
    track_id = state["track_id"]
    archive_root_created = not state["archive_root"].exists()
    original_registry = state["registry_text"]
    original_metadata = state["metadata_text"]
    try:
        require_current_revision(state)
        state["archive_root"].mkdir(parents=True, exist_ok=True)
        ensure_no_symlink(state["archive_root"], repo, "archive directory")
        shutil.move(str(state["source"]), str(state["destination"]))
        registry_text = registry_without_block(
            state["registry_lines"], state["entry"], state["note_end"]
        )
        state["registry_path"].write_text(registry_text, encoding="utf-8")
        write_metadata(state["destination"] / "metadata.json", state["metadata"])
        git(
            repo,
            "add",
            "-A",
            "--",
            f"conductor/tracks/{track_id}",
            f"conductor/archive/{track_id}",
            "conductor/tracks.md",
        )
        verify_staged_paths(repo, track_id)
        git(repo, "commit", "-m", ARCHIVE_MESSAGE.format(track_id=track_id))
        state["archive_commit"] = git(repo, "rev-parse", "HEAD")
        commit = verify_archive_commit(repo, track_id, state["branch"])
        require_current_revision(state, expected_head=commit)
    except ArchiveError as error:
        rollback(state, original_registry, original_metadata, archive_root_created)
        raise ArchiveError(
            f"archive mutation failed: {error}; rollback completed; "
            "no archive commit was created"
        ) from error
    except Exception as error:
        rollback(state, original_registry, original_metadata, archive_root_created)
        stop(
            f"archive mutation failed: {error}; rollback completed; "
            "no archive commit was created"
        )

    push = subprocess.run(
        ["git", "push", state["remote"], f"{commit}:{state['remote_branch']}"],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if push.returncode != 0:
        print(
            f"ARCHIVE LOCAL-ONLY: commit {commit} exists locally but push failed: "
            f"{push.stderr.strip() or push.stdout.strip()}",
            file=sys.stderr,
        )
        return 1
    fetch_upstream(repo, state["remote"], state["remote_branch"])
    remote_tip = git(repo, "rev-parse", "--verify", state["remote_ref"])
    if not ancestry(repo, commit, remote_tip):
        stop("remote branch does not contain the archive commit after push")
    print(f"ARCHIVED: {track_id}")
    print(f"COMMIT: {commit}")
    return 0


def run(args: argparse.Namespace) -> int:
    if args.resume_push:
        try:
            return resume_push(args)
        except ArchiveError as error:
            raise ArchiveError(
                f"{error}\nThe existing local archive commit was not changed."
            ) from error
    try:
        state = preflight(args)
    except ArchiveError as error:
        raise ArchiveError(f"{error}\nNo archive mutation was performed.") from error
    repo = state["repo"]
    if args.dry_run:
        print(f"DRY-RUN: track {state['track_id']} is eligible for archive")
        return 0
    if not args.apply:
        prompt_confirmation(state["track_id"])
    with archive_lock(repo, state["track_id"]):
        state = preflight(args)
        fetch_upstream(repo, state["remote"], state["remote_branch"])
        require_current_revision(state)
        sync_state, _ = branch_state(repo, state["remote_ref"])
        if sync_state == "diverged":
            stop("local and remote branches have diverged")
        if sync_state == "remote-ahead":
            require_current_revision(state)
            git(repo, "merge", "--ff-only", state["remote_ref"])
            state = preflight(args)
            fetch_upstream(repo, state["remote"], state["remote_branch"])
            require_current_revision(state)
            sync_state, _ = branch_state(repo, state["remote_ref"])
        if sync_state == "local-ahead":
            require_current_revision(state)
            push = subprocess.run(
                ["git", "push", state["remote"], f"{state['original_head']}:{state['remote_branch']}"],
                cwd=repo,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            if push.returncode != 0:
                stop(f"implementation push failed: {push.stderr.strip() or push.stdout.strip()}")
            fetch_upstream(repo, state["remote"], state["remote_branch"])
            require_current_revision(state)
            sync_state, _ = branch_state(repo, state["remote_ref"])
        if sync_state != "equal":
            stop("branch could not be synchronized without divergent history")
        return mutate_and_push(state)


def main() -> int:
    try:
        return run(parse_args())
    except ArchiveError as error:
        print(f"STOP: {error}", file=sys.stderr)
        return 1
    except (KeyboardInterrupt, EOFError):
        print("STOP: archive operation cancelled", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
