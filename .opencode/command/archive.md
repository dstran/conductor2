---
description: Safely resume Conductor review cleanup for a completed track and push the archive commit
agent: build
---

# `/conductor/archive`

Use this command only from the selected track's own worktree and branch. Do not
run it from the base branch or from a different track worktree. The command is
the recovery path when `/conductor/review` completed but its interactive Archive
choice is no longer available; it does not replace `/conductor/cleanup`, which
removes a merged worktree and local branch.

Accepted invocations are:

```text
/conductor/archive <track_id>
/conductor/archive --dry-run <track_id>
/conductor/archive --apply <track_id>
/conductor/archive --resume-push <track_id>
```

`--dry-run` performs read-only preflight and prints whether the track is
eligible. The default mode asks for confirmation before synchronization and
mutation. `--apply` supplies that confirmation non-interactively.
`--resume-push` is only for an existing local archive commit after its final
push failed; it must not repeat the directory move or metadata edit.

## Helper resolution and execution

Resolve the helper in this order, then pass the original command arguments to
it unchanged. The repository-local helper must win over the installed fallback:

```bash
repo_root="$(git rev-parse --show-toplevel)"
if [ -f "$repo_root/conductor/scripts/archive-track.py" ]; then
  helper="$repo_root/conductor/scripts/archive-track.py"
elif [ -f "$HOME/.config/opencode/command/conductor/assets/scripts/archive-track.py" ]; then
  helper="$HOME/.config/opencode/command/conductor/assets/scripts/archive-track.py"
else
  echo "STOP: archive-track.py is not installed or present in this repository" >&2
  exit 1
fi
python3 "$helper" $ARGUMENTS
```

The helper accepts metadata status `complete` or `awaiting-review`. It stops
without archive mutation for `in-progress`, `blocked`, malformed or mismatched
metadata, missing review/plan evidence, unsafe paths, dirty worktrees, orphan
registry notes, shared live-track registry state, missing upstreams, and
divergent history. Preflight failures include the observed failure and state
that no archive mutation was performed.

After confirmation, it fetches the configured upstream. A remote-ahead branch
is fast-forwarded only; local implementation commits are pushed before the
archive mutation; divergent history and push races stop without force-push.
The normal archive operation moves:

```text
conductor/tracks/<track_id>/ -> conductor/archive/<track_id>/
```

It removes the complete contiguous registry block, changes metadata status to
`archived` with a refreshed `updatedAt`, stages only the expected paths, and
creates exactly:

```text
chore(conductor): Archive track '<track_id>'
```

The archive commit is pushed to the configured tracking branch and verified on
the remote. If that final push fails, the command reports the archive as
local-only. Re-run with `--resume-push <track_id>` after resolving the remote
problem to publish only that existing archive commit.
