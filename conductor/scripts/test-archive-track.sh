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
    [ ! -e "$1" ] || fail "expected path to be absent: $1"
}

assert_contains() {
    value=$1
    expected=$2
    case $value in
        *"$expected"*) ;;
        *) fail "expected output to contain: $expected" ;;
    esac
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

    rm "$REMOTE/hooks/update"
    run_helper --resume-push demo
    [ "$run_status" -eq 0 ] || fail "resume-push failed: $output"
    [ "$(git --git-dir="$REMOTE" rev-parse refs/heads/track/demo)" = "$local_tip" ] || \
        fail 'resume-push did not publish the archive commit'
    assert_absent "$REPO/conductor/tracks/demo"
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
printf '%s\n' 'PASS: archive helper basic contract'
