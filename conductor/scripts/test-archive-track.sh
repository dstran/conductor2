#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
helper=$script_dir/archive-track.py
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/test-archive-track.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_file() {
    [ -e "$1" ] || fail "expected file or directory: $1"
}

assert_absent() {
    [ ! -e "$1" ] && [ ! -L "$1" ] || fail "expected path to be absent: $1"
}

assert_contains() {
    value=$1
    expected=$2
    case $value in
        *"$expected"*) ;;
        *) fail "expected output to contain: $expected" ;;
    esac
}

assert_clean_index() {
    git -C "$REPO" diff --cached --quiet || fail 'Git index contains unexpected staged changes'
}

assert_preflight_stop() {
    [ "$run_status" -ne 0 ] || fail 'unsafe archive unexpectedly succeeded'
    assert_contains "$output" 'STOP:'
    assert_absent "$REPO/conductor/archive"
    assert_file "$REPO/conductor/tracks/demo"
    assert_clean_index
    [ "$(git -C "$REPO" log -1 --format=%s)" != "chore(conductor): Archive track 'demo'" ] || \
        fail 'preflight failure created an archive commit'
}

git_configure() {
    repo=$1
    git -C "$repo" config user.name 'Archive Test'
    git -C "$repo" config user.email archive-test@example.invalid
}

create_fixture() {
    status=$1
    name=$2
    fixture=$work_dir/$name
    remote=$fixture/remote.git
    repo=$fixture/repo

    mkdir -p "$fixture"
    git init --bare -q "$remote"
    git init -q -b track/demo "$repo"
    git_configure "$repo"
    git -C "$repo" remote add origin "$remote"

    mkdir -p "$repo/conductor/tracks/demo"
    cat >"$repo/conductor/tracks/demo/metadata.json" <<EOF
{
  "id": "demo",
  "type": "feature",
  "status": "$status",
  "branch": "track/demo",
  "created": "2026-11-06T00:00:00Z",
  "updatedAt": "2026-11-06T00:00:00Z"
}
EOF
    cat >"$repo/conductor/tracks/demo/plan.md" <<'EOF'
# Plan: Demo

## Phase 1: Implement [checkpoint: abcdef1]

- [x] Task: Implement demo [backend-logic] abcdef1
EOF
    printf '%s\n' '# Spec: Demo' >"$repo/conductor/tracks/demo/spec.md"
    printf '%s\n' '# Review: Demo' >"$repo/conductor/tracks/demo/review.md"
    printf '%s\n' '# Index' >"$repo/conductor/index.md"

    if [ "$status" = awaiting-review ]; then
        cat >"$repo/conductor/tracks.md" <<'EOF'
# Tracks Registry

## Active

- [~] **Track: Demo** *Link: [tracks/demo/plan.md](./tracks/demo/plan.md)*
  Status: implementation complete — awaiting review.

## Blocked
EOF
    else
        cat >"$repo/conductor/tracks.md" <<'EOF'
# Tracks Registry

## Active

- [x] **Track: Demo** *Link: [tracks/demo/plan.md](./tracks/demo/plan.md)*

## Blocked
EOF
    fi

    git -C "$repo" add conductor
    git -C "$repo" commit -q -m 'test: create archive fixture'
    git -C "$repo" push -q -u origin track/demo

    FIXTURE=$fixture
    REPO=$repo
    REMOTE=$remote
    export FIXTURE REPO REMOTE
}

run_helper() {
    set +e
    output=$(cd "$REPO" && python3 "$helper" "$@" 2>&1)
    run_status=$?
    set -e
    export output run_status
}

assert_pushed_archive() {
    assert_absent "$REPO/conductor/tracks/demo"
    assert_file "$REPO/conductor/archive/demo/metadata.json"
    assert_contains "$(cat "$REPO/conductor/archive/demo/metadata.json")" '"status": "archived"'
    assert_contains "$(cat "$REPO/conductor/tracks.md")" '## Active'
    if grep -F 'Track: Demo' "$REPO/conductor/tracks.md" >/dev/null; then
        fail 'active registry entry remains'
    fi
    [ "$(git -C "$REPO" log -1 --format=%s)" = "chore(conductor): Archive track 'demo'" ] || \
        fail 'archive commit message is incorrect'
    local_tip=$(git -C "$REPO" rev-parse HEAD)
    remote_tip=$(git --git-dir="$REMOTE" rev-parse refs/heads/track/demo)
    [ "$local_tip" = "$remote_tip" ] || fail 'archive commit was not pushed'
}

test_complete_archive() {
    create_fixture complete complete
    run_helper --apply demo
    [ "$run_status" -eq 0 ] || fail "complete archive failed: $output"
    assert_pushed_archive
}

test_awaiting_review_archive() {
    create_fixture awaiting-review awaiting
    run_helper --apply demo
    [ "$run_status" -eq 0 ] || fail "awaiting-review archive failed: $output"
    assert_pushed_archive
    if grep -F 'awaiting review' "$REPO/conductor/tracks.md" >/dev/null; then
        fail 'orphan awaiting-review note remains'
    fi
}

test_hard_stop_status() {
    for status in in-progress blocked; do
        create_fixture "$status" "$status"
        run_helper --apply demo
        [ "$run_status" -ne 0 ] || fail "$status unexpectedly archived"
        assert_contains "$output" 'STOP:'
        assert_absent "$REPO/conductor/archive"
        assert_file "$REPO/conductor/tracks/demo"
        [ "$(git -C "$REPO" log -1 --format=%s)" = 'test: create archive fixture' ] || \
            fail "$status changed the repository"
    done
}

test_dry_run() {
    create_fixture complete dry-run
    before=$(git -C "$REPO" rev-parse HEAD)
    remote_before=$(git --git-dir="$REMOTE" rev-parse refs/heads/track/demo)
    run_helper --dry-run demo
    [ "$run_status" -eq 0 ] || fail "dry-run failed: $output"
    assert_absent "$REPO/conductor/archive"
    assert_file "$REPO/conductor/tracks/demo"
    [ "$(git -C "$REPO" rev-parse HEAD)" = "$before" ] || fail 'dry-run created a commit'
    [ "$(git --git-dir="$REMOTE" rev-parse refs/heads/track/demo)" = "$remote_before" ] || \
        fail 'dry-run changed the remote'
}

test_remote_ahead_fast_forward() {
    create_fixture complete remote-ahead
    other=$FIXTURE/other
    git clone -q --branch track/demo "$REMOTE" "$other"
    git_configure "$other"
    printf '%s\n' remote >"$other/remote-change.txt"
    git -C "$other" add remote-change.txt
    git -C "$other" commit -q -m 'test: advance remote branch'
    git -C "$other" push -q origin track/demo

    run_helper --apply demo
    [ "$run_status" -eq 0 ] || fail "remote-ahead archive failed: $output"
    assert_pushed_archive
    assert_file "$REPO/remote-change.txt"
}

test_local_ahead_push() {
    create_fixture complete local-ahead
    printf '%s\n' local >"$REPO/local-change.txt"
    git -C "$REPO" add local-change.txt
    git -C "$REPO" commit -q -m 'test: advance local branch'

    run_helper --apply demo
    [ "$run_status" -eq 0 ] || fail "local-ahead archive failed: $output"
    assert_pushed_archive
    assert_file "$REPO/local-change.txt"
}

test_divergent_stops() {
    create_fixture complete divergent
    other=$FIXTURE/other
    git clone -q --branch track/demo "$REMOTE" "$other"
    git_configure "$other"
    printf '%s\n' local >"$REPO/local-change.txt"
    git -C "$REPO" add local-change.txt
    git -C "$REPO" commit -q -m 'test: local divergence'
    printf '%s\n' remote >"$other/remote-change.txt"
    git -C "$other" add remote-change.txt
    git -C "$other" commit -q -m 'test: remote divergence'
    git -C "$other" push -q origin track/demo
    before=$(git -C "$REPO" rev-parse HEAD)

    run_helper --apply demo
    [ "$run_status" -ne 0 ] || fail 'divergent branch unexpectedly archived'
    assert_contains "$output" 'diverg'
    assert_absent "$REPO/conductor/archive"
    assert_file "$REPO/conductor/tracks/demo"
    [ "$(git -C "$REPO" rev-parse HEAD)" = "$before" ] || fail 'divergence changed local HEAD'
}

test_missing_remote_stops() {
    create_fixture complete missing-remote
    git -C "$REPO" push -q origin --delete track/demo
    run_helper --apply demo
    [ "$run_status" -ne 0 ] || fail 'missing remote branch unexpectedly recreated'
    assert_contains "$output" 'remote'
    assert_absent "$REPO/conductor/archive"
    assert_file "$REPO/conductor/tracks/demo"
}

test_resume_push() {
    create_fixture complete resume-push
    cat >"$REMOTE/hooks/update" <<'EOF'
#!/bin/sh
printf '%s\n' 'archive test rejection' >&2
exit 1
EOF
    chmod +x "$REMOTE/hooks/update"

    run_helper --apply demo
    [ "$run_status" -ne 0 ] || fail 'rejected archive push unexpectedly succeeded'
    assert_contains "$output" 'LOCAL-ONLY'
    assert_absent "$REPO/conductor/tracks/demo"
    assert_file "$REPO/conductor/archive/demo"
    local_tip=$(git -C "$REPO" rev-parse HEAD)
    remote_tip=$(git --git-dir="$REMOTE" rev-parse refs/heads/track/demo)
    [ "$local_tip" != "$remote_tip" ] || fail 'rejected push changed the remote'

    cat >"$REMOTE/hooks/update" <<'EOF'
#!/bin/sh
printf '%s\n' 'archive resume rejection' >&2
exit 1
EOF
    chmod +x "$REMOTE/hooks/update"
    run_helper --resume-push demo
    [ "$run_status" -ne 0 ] || fail 'rejected resume push unexpectedly succeeded'
    case $output in
        *'No archive mutation was performed.'*) fail 'resume failure misreported as no archive mutation' ;;
    esac
    assert_contains "$output" 'existing local archive'

    rm "$REMOTE/hooks/update"
    run_helper --resume-push demo
    [ "$run_status" -eq 0 ] || fail "resume-push failed: $output"
    [ "$(git --git-dir="$REMOTE" rev-parse refs/heads/track/demo)" = "$local_tip" ] || \
        fail 'resume-push did not publish the archive commit'
    assert_absent "$REPO/conductor/tracks/demo"
}

test_base_branch_stops() {
    create_fixture complete base-branch
    git -C "$REPO" switch -q -c main
    sed -i.bak 's#"branch": "track/demo"#"branch": "main"#' \
        "$REPO/conductor/tracks/demo/metadata.json"
    rm -f "$REPO/conductor/tracks/demo/metadata.json.bak"
    git -C "$REPO" add conductor/tracks/demo/metadata.json
    git -C "$REPO" commit -q -m 'test: configure base branch metadata'
    git -C "$REPO" push -q -u origin main

    run_helper --apply demo
    assert_preflight_stop
    assert_contains "$output" 'track worktree'
    [ "$(git -C "$REPO" branch --show-current)" = main ] || fail 'base branch changed'
}

test_post_commit_path_guard_rolls_back() {
    create_fixture complete post-commit-path
    original_head=$(git -C "$REPO" rev-parse HEAD)
    hooks_dir="$REPO/$(git -C "$REPO" rev-parse --git-path hooks)"
    cat >"$hooks_dir/pre-commit" <<'EOF'
#!/bin/sh
printf '%s\n' injected > unrelated-hook.txt
git add unrelated-hook.txt
EOF
    chmod +x "$hooks_dir/pre-commit"

    run_helper --apply demo
    [ "$run_status" -ne 0 ] || fail 'unrelated post-stage path unexpectedly archived'
    assert_contains "$output" 'rollback'
    assert_file "$REPO/conductor/tracks/demo"
    assert_absent "$REPO/conductor/archive"
    [ "$(git -C "$REPO" rev-parse HEAD)" = "$original_head" ] || \
        fail 'unrelated post-stage path left an archive commit'
    assert_clean_index
    assert_file "$REPO/unrelated-hook.txt"
}

test_post_commit_verification_rolls_back_commit() {
    create_fixture complete post-commit-verify
    original_head=$(git -C "$REPO" rev-parse HEAD)
    original_registry=$(cat "$REPO/conductor/tracks.md")
    hooks_dir="$REPO/$(git -C "$REPO" rev-parse --git-path hooks)"
    cat >"$hooks_dir/post-commit" <<'EOF'
#!/bin/sh
printf '%s\n' '- [x] **Track: Demo** *Link: [tracks/demo/plan.md](./tracks/demo/plan.md)*' >> conductor/tracks.md
EOF
    chmod +x "$hooks_dir/post-commit"

    run_helper --apply demo
    [ "$run_status" -ne 0 ] || fail 'post-commit verification failure unexpectedly succeeded'
    assert_contains "$output" 'rollback'
    assert_file "$REPO/conductor/tracks/demo"
    assert_absent "$REPO/conductor/archive"
    [ "$(git -C "$REPO" rev-parse HEAD)" = "$original_head" ] || \
        fail 'post-commit verification failure left an archive commit'
    [ "$(cat "$REPO/conductor/tracks.md")" = "$original_registry" ] || \
        fail 'post-commit verification failure did not restore registry'
    assert_clean_index
}

test_final_push_descendant_is_accepted() {
    create_fixture complete final-descendant
    cat >"$REMOTE/hooks/post-receive" <<'EOF'
#!/bin/sh
while read -r old new ref; do
    tree=$(git rev-parse "$new^{tree}")
    child=$(printf '%s\n' 'remote follow-up' | git commit-tree "$tree" -p "$new")
    git update-ref "$ref" "$child" "$new"
done
EOF
    chmod +x "$REMOTE/hooks/post-receive"

    run_helper --apply demo
    [ "$run_status" -eq 0 ] || fail "remote descendant archive failed: $output"
    assert_absent "$REPO/conductor/tracks/demo"
    local_tip=$(git -C "$REPO" rev-parse HEAD)
    remote_tip=$(git --git-dir="$REMOTE" rev-parse refs/heads/track/demo)
    [ "$local_tip" != "$remote_tip" ] || fail 'remote descendant fixture did not advance remote'
    git -C "$REPO" merge-base --is-ancestor "$local_tip" "$remote_tip" || \
        fail 'remote descendant does not contain archive commit'
}

test_archive_content_guard_rolls_back() {
    create_fixture complete archive-content
    original_head=$(git -C "$REPO" rev-parse HEAD)
    hooks_dir="$REPO/$(git -C "$REPO" rev-parse --git-path hooks)"
    cat >"$hooks_dir/pre-commit" <<'EOF'
#!/bin/sh
printf '%s\n' tampered > conductor/archive/demo/spec.md
git add conductor/archive/demo/spec.md
EOF
    chmod +x "$hooks_dir/pre-commit"

    run_helper --apply demo
    [ "$run_status" -ne 0 ] || fail 'tampered archive content unexpectedly succeeded'
    assert_contains "$output" 'contents'
    assert_contains "$output" 'rollback'
    assert_file "$REPO/conductor/tracks/demo"
    assert_absent "$REPO/conductor/archive"
    [ "$(git -C "$REPO" rev-parse HEAD)" = "$original_head" ] || \
        fail 'tampered archive content left an archive commit'
    assert_clean_index
}

test_post_push_local_change_is_reported() {
    create_fixture complete post-push-local-change
    original_head=$(git -C "$REPO" rev-parse HEAD)
    hooks_dir="$REPO/$(git -C "$REPO" rev-parse --git-path hooks)"
    cat >"$hooks_dir/pre-push" <<'EOF'
#!/bin/sh
printf '%s\n' follow-up > local-follow-up.txt
git add local-follow-up.txt
git commit -q -m 'test: advance local branch during push'
EOF
    chmod +x "$hooks_dir/pre-push"

    run_helper --apply demo
    [ "$run_status" -ne 0 ] || fail 'local post-push change was falsely reported as success'
    assert_contains "$output" 'LOCAL STATE CHANGED'
    assert_absent "$REPO/conductor/tracks/demo"
    assert_file "$REPO/conductor/archive/demo"
    [ "$(git -C "$REPO" rev-parse HEAD)" != "$original_head" ] || \
        fail 'pre-push hook did not advance local branch'
    archive_commit=$(git -C "$REPO" log --all --format='%H %s' | awk '$0 ~ /chore\(conductor\): Archive track/ {print $1; exit}')
    [ -n "$archive_commit" ] || fail 'archive commit was not created'
    remote_tip=$(git --git-dir="$REMOTE" rev-parse refs/heads/track/demo)
    [ "$remote_tip" = "$archive_commit" ] || fail 'remote did not receive archive commit'
}

test_remote_deletion_race_does_not_recreate_branch() {
    create_fixture complete remote-deletion-race
    hooks_dir="$REPO/$(git -C "$REPO" rev-parse --git-path hooks)"
    cat >"$hooks_dir/pre-push" <<EOF
#!/bin/sh
git --git-dir="$REMOTE" update-ref -d refs/heads/track/demo
EOF
    chmod +x "$hooks_dir/pre-push"

    run_helper --apply demo
    [ "$run_status" -ne 0 ] || fail 'deleted remote branch was recreated during push'
    assert_contains "$output" 'LOCAL-ONLY'
    if git --git-dir="$REMOTE" show-ref --verify --quiet refs/heads/track/demo; then
        fail 'remote deletion race recreated the branch'
    fi
    assert_absent "$REPO/conductor/tracks/demo"
    assert_file "$REPO/conductor/archive/demo"
}

test_shared_live_track_stops() {
    create_fixture complete shared-live
    mkdir -p "$REPO/conductor/tracks/other"
    printf '%s\n' '# Other plan' >"$REPO/conductor/tracks/other/plan.md"
    cat >>"$REPO/conductor/tracks.md" <<'EOF'

- [x] **Track: Other** *Link: [tracks/other/plan.md](./tracks/other/plan.md)*
EOF
    git -C "$REPO" add conductor
    git -C "$REPO" commit -q -m 'test: add shared live track'
    git -C "$REPO" push -q origin track/demo

    run_helper --apply demo
    assert_preflight_stop
    assert_contains "$output" 'shared'
}

test_symlink_source_stops() {
    create_fixture complete symlink-source
    outside=$FIXTURE/outside-source
    mkdir -p "$outside"
    printf '%s\n' protected >"$outside/protected.txt"
    rm -rf "$REPO/conductor/tracks/demo"
    ln -s "$outside" "$REPO/conductor/tracks/demo"

    run_helper --apply demo
    assert_preflight_stop
    assert_contains "$output" 'symlink'
    [ "$(cat "$outside/protected.txt")" = protected ] || fail 'source symlink target changed'
}

test_symlink_metadata_stops() {
    create_fixture complete symlink-metadata
    outside=$FIXTURE/outside-metadata
    mkdir -p "$outside"
    cp "$REPO/conductor/tracks/demo/metadata.json" "$outside/metadata.json"
    rm "$REPO/conductor/tracks/demo/metadata.json"
    ln -s "$outside/metadata.json" "$REPO/conductor/tracks/demo/metadata.json"

    run_helper --apply demo
    assert_preflight_stop
    assert_contains "$output" 'symlink'
    assert_file "$outside/metadata.json"
}

test_symlink_registry_stops() {
    create_fixture complete symlink-registry
    outside=$FIXTURE/outside-registry
    mkdir -p "$outside"
    cp "$REPO/conductor/tracks.md" "$outside/tracks.md"
    rm "$REPO/conductor/tracks.md"
    ln -s "$outside/tracks.md" "$REPO/conductor/tracks.md"

    run_helper --apply demo
    assert_preflight_stop
    assert_contains "$output" 'symlink'
    grep -F 'Track: Demo' "$outside/tracks.md" >/dev/null || fail 'registry symlink target changed'
}

test_symlink_archive_stops() {
    create_fixture complete symlink-archive
    outside=$FIXTURE/outside-archive
    mkdir -p "$outside"
    ln -s "$outside" "$REPO/conductor/archive"

    run_helper --apply demo
    [ "$run_status" -ne 0 ] || fail 'archive symlink unexpectedly accepted'
    assert_contains "$output" 'STOP:'
    [ -L "$REPO/conductor/archive" ] || fail 'archive symlink was changed'
    assert_file "$REPO/conductor/tracks/demo"
    assert_clean_index
    assert_contains "$output" 'symlink'
    assert_absent "$outside/demo"
}

test_mismatched_metadata_stops() {
    for field in id branch; do
        create_fixture complete "mismatched-$field"
        if [ "$field" = id ]; then
            sed -i.bak 's/"id": "demo"/"id": "other"/' "$REPO/conductor/tracks/demo/metadata.json"
        else
            sed -i.bak 's#"branch": "track/demo"#"branch": "track/other"#' "$REPO/conductor/tracks/demo/metadata.json"
        fi
        rm -f "$REPO/conductor/tracks/demo/metadata.json.bak"
        run_helper --apply demo
        assert_preflight_stop
        assert_contains "$output" 'metadata'
    done
}

test_malformed_metadata_stops() {
    create_fixture complete malformed-json
    printf '%s\n' '{ malformed' >"$REPO/conductor/tracks/demo/metadata.json"
    run_helper --apply demo
    assert_preflight_stop
    assert_contains "$output" 'valid JSON'
}

test_invalid_created_timestamp_stops() {
    create_fixture complete invalid-created
    sed -i.bak 's/"created": "2026-11-06T00:00:00Z"/"created": "not-a-timestamp"/' \
        "$REPO/conductor/tracks/demo/metadata.json"
    rm -f "$REPO/conductor/tracks/demo/metadata.json.bak"
    git -C "$REPO" add conductor/tracks/demo/metadata.json
    git -C "$REPO" commit -q -m 'test: corrupt created timestamp'
    git -C "$REPO" push -q origin track/demo
    run_helper --apply demo
    assert_preflight_stop
    assert_contains "$output" 'created'
}

test_orphan_registry_note_stops() {
    create_fixture complete orphan-note
    awk '
        /^## Blocked$/ && !added {
            print "Status: implementation complete — awaiting review."
            print ""
            added = 1
        }
        { print }
    ' "$REPO/conductor/tracks.md" >"$REPO/conductor/tracks.md.tmp"
    mv "$REPO/conductor/tracks.md.tmp" "$REPO/conductor/tracks.md"
    git -C "$REPO" add conductor/tracks.md
    git -C "$REPO" commit -q -m 'test: add orphan registry note'
    git -C "$REPO" push -q origin track/demo
    run_helper --apply demo
    assert_preflight_stop
    assert_contains "$output" 'registry'
}

test_dirty_worktree_stops() {
    for dirty_kind in untracked staged; do
        create_fixture complete "dirty-$dirty_kind"
        if [ "$dirty_kind" = untracked ]; then
            printf '%s\n' unrelated >"$REPO/unrelated.txt"
        else
            printf '%s\n' unrelated >"$REPO/staged.txt"
            git -C "$REPO" add staged.txt
        fi
        run_helper --apply demo
        if [ "$dirty_kind" = untracked ]; then
            assert_preflight_stop
        else
            [ "$run_status" -ne 0 ] || fail 'staged dirty worktree unexpectedly archived'
            assert_contains "$output" 'STOP:'
            assert_absent "$REPO/conductor/archive"
            assert_file "$REPO/conductor/tracks/demo"
            [ "$(git -C "$REPO" log -1 --format=%s)" != "chore(conductor): Archive track 'demo'" ] || \
                fail 'staged dirty worktree created an archive commit'
        fi
        assert_contains "$output" 'dirty'
        if [ "$dirty_kind" = staged ]; then
            git -C "$REPO" diff --cached --name-only | grep -F 'staged.txt' >/dev/null || \
                fail 'preflight did not preserve the unrelated staged file'
        fi
    done
}

test_mutation_failure_rolls_back() {
    create_fixture complete mutation-failure
    original_metadata=$(cat "$REPO/conductor/tracks/demo/metadata.json")
    original_registry=$(cat "$REPO/conductor/tracks.md")
    original_head=$(git -C "$REPO" rev-parse HEAD)
    hooks_dir="$REPO/$(git -C "$REPO" rev-parse --git-path hooks)"
    cat >"$hooks_dir/pre-commit" <<'EOF'
#!/bin/sh
printf '%s\n' 'injected commit failure' >&2
exit 1
EOF
    chmod +x "$hooks_dir/pre-commit"

    run_helper --apply demo
    [ "$run_status" -ne 0 ] || fail 'injected mutation failure unexpectedly succeeded'
    assert_contains "$output" 'rollback'
    assert_file "$REPO/conductor/tracks/demo"
    assert_absent "$REPO/conductor/archive"
    [ "$(cat "$REPO/conductor/tracks/demo/metadata.json")" = "$original_metadata" ] || \
        fail 'mutation failure did not restore metadata'
    [ "$(cat "$REPO/conductor/tracks.md")" = "$original_registry" ] || \
        fail 'mutation failure did not restore registry'
    [ "$(git -C "$REPO" rev-parse HEAD)" = "$original_head" ] || \
        fail 'mutation failure changed HEAD'
    assert_clean_index
}

test_command_surface() {
    repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
    command_file=$repo_root/.opencode/command/archive.md
    [ -f "$command_file" ] || fail 'archive command wrapper is missing'
    for mode in --dry-run --apply --resume-push; do
        grep -F -- "$mode" "$command_file" >/dev/null || \
            fail "archive command wrapper does not document $mode"
    done
    local_line=$(grep -nF 'conductor/scripts/archive-track.py' "$command_file" | head -n 1 | cut -d: -f1)
    fallback_line=$(grep -nF 'assets/scripts/archive-track.py' "$command_file" | head -n 1 | cut -d: -f1)
    [ -n "$local_line" ] || fail 'archive command wrapper lacks local helper resolution'
    [ -n "$fallback_line" ] || fail 'archive command wrapper lacks installed helper fallback'
    [ "$local_line" -lt "$fallback_line" ] || fail 'installed helper is checked before local helper'
    grep -F "chore(conductor): Archive track '<track_id>'" "$command_file" >/dev/null || \
        fail 'archive command wrapper omits the exact archive commit message'
    grep -F 'archive-track.py' "$repo_root/install.sh" >/dev/null || \
        fail 'installer does not install archive-track.py'
}

test_complete_archive
test_awaiting_review_archive
test_hard_stop_status
test_dry_run
test_remote_ahead_fast_forward
test_local_ahead_push
test_divergent_stops
test_missing_remote_stops
test_resume_push
test_base_branch_stops
test_post_commit_path_guard_rolls_back
test_post_commit_verification_rolls_back_commit
test_final_push_descendant_is_accepted
test_archive_content_guard_rolls_back
test_post_push_local_change_is_reported
test_remote_deletion_race_does_not_recreate_branch
test_shared_live_track_stops
test_symlink_source_stops
test_symlink_metadata_stops
test_symlink_registry_stops
test_symlink_archive_stops
test_mismatched_metadata_stops
test_malformed_metadata_stops
test_invalid_created_timestamp_stops
test_orphan_registry_note_stops
test_dirty_worktree_stops
test_mutation_failure_rolls_back
test_command_surface
printf '%s\n' 'PASS: archive helper safety contract'
