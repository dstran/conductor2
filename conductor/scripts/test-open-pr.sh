#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
dispatcher=$script_dir/open-pr.sh
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/test-open-pr.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT HUP INT TERM

fake_bin=$work_dir/bin
repo=$work_dir/repo
log_dir=$work_dir/logs
mkdir "$fake_bin" "$log_dir" "$repo"
git -C "$repo" init -q

cat >"$fake_bin/git" <<'EOF'
#!/bin/sh
if [ "$#" -eq 3 ] && [ "$1" = remote ] && [ "$2" = get-url ] && [ "$3" = origin ]; then
    printf '%s\n' "$REMOTE_URL"
    exit 0
fi
exit 1
EOF

cat >"$fake_bin/gh" <<'EOF'
#!/bin/sh
if [ "$1" = auth ] && [ "$2" = status ]; then
    printf '%s\n' "$@" >"$FAKE_LOG_DIR/gh-auth"
    exit "${GH_AUTH_STATUS:-0}"
fi
if [ "$1" = pr ] && [ "$2" = create ]; then
    printf '%s\n' "$@" >"$FAKE_LOG_DIR/gh"
    exit "${GH_CREATE_STATUS:-0}"
fi
exit 1
EOF

cat >"$fake_bin/glab" <<'EOF'
#!/bin/sh
if [ "$1" = auth ] && [ "$2" = status ]; then
    printf '%s\n' "$@" >"$FAKE_LOG_DIR/glab-auth"
    exit "${GLAB_AUTH_STATUS:-0}"
fi
if [ "$1" = mr ] && [ "$2" = create ]; then
    printf '%s\n' "$@" >"$FAKE_LOG_DIR/glab"
    exit "${GLAB_CREATE_STATUS:-0}"
fi
exit 1
EOF
chmod +x "$fake_bin/git" "$fake_bin/gh" "$fake_bin/glab"

body_file="$work_dir/review body.md"
printf '%s\n' review >"$body_file"

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_contains() {
    value=$1
    expected=$2
    case $value in
        *"$expected"*) ;;
        *) fail "expected output to contain: $expected" ;;
    esac
}

assert_log() {
    provider=$1
    shift
    expected=$work_dir/expected
    : >"$expected"
    for argument do
        printf '%s\n' "$argument" >>"$expected"
    done
    [ -f "$log_dir/$provider" ] || fail "expected $provider to be called"
    cmp -s "$expected" "$log_dir/$provider" || fail "unexpected $provider arguments"
}

assert_named_log() {
    log_name=$1
    shift
    expected=$work_dir/expected
    : >"$expected"
    for argument do
        printf '%s\n' "$argument" >>"$expected"
    done
    [ -f "$log_dir/$log_name" ] || fail "expected $log_name to be called"
    cmp -s "$expected" "$log_dir/$log_name" || fail "unexpected $log_name arguments"
}

run_dispatcher() {
    set +e
    output=$(
        cd "$repo" && \
        REMOTE_URL=$REMOTE_URL \
        FAKE_LOG_DIR=$log_dir \
        GH_AUTH_STATUS=${GH_AUTH_STATUS:-0} \
        GH_CREATE_STATUS=${GH_CREATE_STATUS:-0} \
        GLAB_AUTH_STATUS=${GLAB_AUTH_STATUS:-0} \
        GLAB_CREATE_STATUS=${GLAB_CREATE_STATUS:-0} \
        PATH=$fake_bin:$PATH \
        sh "$dispatcher" track/demo main Demo "${DISPATCHER_BODY_FILE:-$body_file}" 2>&1
    )
    run_status=$?
    set -e
}

run_case() {
    name=$1
    expected_status=$2
    remote=$3
    provider=$4
    shift 4
    rm -f "$log_dir/gh" "$log_dir/glab"
    REMOTE_URL=$remote GH_AUTH_STATUS=0 GH_CREATE_STATUS=0 GLAB_AUTH_STATUS=0 GLAB_CREATE_STATUS=0
    export REMOTE_URL GH_AUTH_STATUS GH_CREATE_STATUS GLAB_AUTH_STATUS GLAB_CREATE_STATUS
    run_dispatcher
    [ "$run_status" -eq "$expected_status" ] || fail "$name returned $run_status"
    assert_log "$provider" "$@"
    if [ "$provider" = gh ]; then
        assert_named_log gh-auth auth status --hostname github.com
    else
        assert_named_log glab-auth auth status
    fi
    other=gh
    [ "$provider" = gh ] && other=glab
    [ ! -e "$log_dir/$other" ] || fail "$name called unselected provider"
}

run_fallback() {
    remote=$1
    reason=$2
    rm -f "$log_dir/gh" "$log_dir/glab"
    REMOTE_URL=$remote GH_AUTH_STATUS=0 GH_CREATE_STATUS=0 GLAB_AUTH_STATUS=0 GLAB_CREATE_STATUS=0
    case $remote in
        *github.com*) GH_AUTH_STATUS=1 ;;
    esac
    export REMOTE_URL GH_AUTH_STATUS GH_CREATE_STATUS GLAB_AUTH_STATUS GLAB_CREATE_STATUS
    run_dispatcher
    [ "$run_status" -eq 1 ] || fail "fallback returned $run_status"
    assert_contains "$output" "$reason"
    assert_contains "$output" 'track/demo'
    assert_contains "$output" 'git push -u origin track/demo'
    case $remote in
        *github.com*)
            assert_contains "$output" 'Open a pull request manually on github.com from track/demo into main.'
            ;;
        *gitlab.com*)
            assert_contains "$output" 'Open a merge request manually on gitlab.com from track/demo into main.'
            ;;
        *)
            assert_contains "$output" 'Open a pull request or merge request manually on forge.example from track/demo into main.'
            ;;
    esac
    [ ! -e "$log_dir/gh" ] || fail "fallback called gh"
    [ ! -e "$log_dir/glab" ] || fail "fallback called glab"
}

run_body_failure() {
    remote=$1
    invalid_body=$2
    rm -f "$log_dir/gh" "$log_dir/glab" "$log_dir/gh-auth" "$log_dir/glab-auth"
    REMOTE_URL=$remote GH_AUTH_STATUS=0 GH_CREATE_STATUS=0 GLAB_AUTH_STATUS=0 GLAB_CREATE_STATUS=0
    DISPATCHER_BODY_FILE=$invalid_body
    export REMOTE_URL GH_AUTH_STATUS GH_CREATE_STATUS GLAB_AUTH_STATUS GLAB_CREATE_STATUS DISPATCHER_BODY_FILE
    run_dispatcher
    [ "$run_status" -eq 1 ] || fail "body failure returned $run_status"
    assert_contains "$output" 'Unable to create review request for GitHub on github.com.'
    assert_contains "$output" 'git push -u origin track/demo'
    assert_contains "$output" 'Open a pull request manually on github.com from track/demo into main.'
    [ ! -e "$log_dir/gh-auth" ] || fail "body failure checked auth"
    if [ -n "${body_fallback_output:-}" ]; then
        [ "$output" = "$body_fallback_output" ] || fail "body failure fallback output changed"
    else
        body_fallback_output=$output
    fi
    unset DISPATCHER_BODY_FILE
}

run_provider_failure() {
    provider=$1
    remote=$2
    log_provider=$provider
    [ "$provider" = github ] && log_provider=gh
    rm -f "$log_dir/gh" "$log_dir/glab"
    REMOTE_URL=$remote GH_AUTH_STATUS=0 GH_CREATE_STATUS=9 GLAB_AUTH_STATUS=0 GLAB_CREATE_STATUS=0
    export REMOTE_URL GH_AUTH_STATUS GH_CREATE_STATUS GLAB_AUTH_STATUS GLAB_CREATE_STATUS
    run_dispatcher
    [ "$run_status" -eq 1 ] || fail "provider failure returned $run_status"
    assert_contains "$output" 'github.com'
    assert_contains "$output" 'git push -u origin track/demo'
    [ -f "$log_dir/$log_provider" ] || fail "provider was not called before fallback"
}

run_missing_cli() {
    remote=$1
    rm -f "$fake_bin/gh" "$log_dir/gh" "$log_dir/glab"
    REMOTE_URL=$remote GH_AUTH_STATUS=0 GH_CREATE_STATUS=0 GLAB_AUTH_STATUS=0 GLAB_CREATE_STATUS=0
    export REMOTE_URL GH_AUTH_STATUS GH_CREATE_STATUS GLAB_AUTH_STATUS GLAB_CREATE_STATUS
    run_dispatcher
    [ "$run_status" -eq 1 ] || fail "missing CLI returned $run_status"
    assert_contains "$output" 'github.com'
    assert_contains "$output" 'git push -u origin track/demo'
}

run_auth_failure() {
    remote=$1
    rm -f "$log_dir/gh" "$log_dir/glab"
    REMOTE_URL=$remote GH_AUTH_STATUS=4 GH_CREATE_STATUS=0 GLAB_AUTH_STATUS=0 GLAB_CREATE_STATUS=0
    export REMOTE_URL GH_AUTH_STATUS GH_CREATE_STATUS GLAB_AUTH_STATUS GLAB_CREATE_STATUS
    run_dispatcher
    [ "$run_status" -eq 1 ] || fail "auth failure returned $run_status"
    assert_contains "$output" 'github.com'
    [ ! -e "$log_dir/gh" ] || fail "auth failure created a request"
}

run_glab_missing_cli() {
    remote=$1
    rm -f "$fake_bin/glab" "$log_dir/gh" "$log_dir/glab"
    REMOTE_URL=$remote GH_AUTH_STATUS=0 GH_CREATE_STATUS=0 GLAB_AUTH_STATUS=0 GLAB_CREATE_STATUS=0
    export REMOTE_URL GH_AUTH_STATUS GH_CREATE_STATUS GLAB_AUTH_STATUS GLAB_CREATE_STATUS
    run_dispatcher
    [ "$run_status" -eq 1 ] || fail "missing glab returned $run_status"
    assert_contains "$output" 'gitlab.com'
    assert_contains "$output" 'git push -u origin track/demo'

    cat >"$fake_bin/glab" <<'EOF'
#!/bin/sh
if [ "$1" = auth ] && [ "$2" = status ]; then exit "${GLAB_AUTH_STATUS:-0}"; fi
if [ "$1" = mr ] && [ "$2" = create ]; then
    printf '%s\n' "$@" >"$FAKE_LOG_DIR/glab"
    exit "${GLAB_CREATE_STATUS:-0}"
fi
exit 1
EOF
    chmod +x "$fake_bin/glab"
}

run_glab_auth_failure() {
    remote=$1
    rm -f "$log_dir/gh" "$log_dir/glab"
    REMOTE_URL=$remote GH_AUTH_STATUS=0 GH_CREATE_STATUS=0 GLAB_AUTH_STATUS=4 GLAB_CREATE_STATUS=0
    export REMOTE_URL GH_AUTH_STATUS GH_CREATE_STATUS GLAB_AUTH_STATUS GLAB_CREATE_STATUS
    run_dispatcher
    [ "$run_status" -eq 1 ] || fail "glab auth failure returned $run_status"
    assert_contains "$output" 'gitlab.com'
    assert_contains "$output" 'git push -u origin track/demo'
    [ ! -e "$log_dir/glab" ] || fail "glab auth failure created a request"
}

run_glab_provider_failure() {
    remote=$1
    rm -f "$log_dir/gh" "$log_dir/glab"
    REMOTE_URL=$remote GH_AUTH_STATUS=0 GH_CREATE_STATUS=0 GLAB_AUTH_STATUS=0 GLAB_CREATE_STATUS=9
    export REMOTE_URL GH_AUTH_STATUS GH_CREATE_STATUS GLAB_AUTH_STATUS GLAB_CREATE_STATUS
    run_dispatcher
    [ "$run_status" -eq 1 ] || fail "glab provider failure returned $run_status"
    assert_contains "$output" 'gitlab.com'
    assert_contains "$output" 'git push -u origin track/demo'
    [ -f "$log_dir/glab" ] || fail "glab was not called before fallback"
}

run_case github_ssh 0 \
    'git@github.com:owner/repo.git' gh \
    pr create --base main --head track/demo --title Demo --body-file "$body_file"
run_case github_https 0 \
    'https://github.com/owner/repo.git' gh \
    pr create --base main --head track/demo --title Demo --body-file "$body_file"
run_case gitlab_ssh 0 \
    'git@gitlab.com:owner/repo.git' glab \
    mr create --source-branch track/demo --target-branch main --title Demo --description-file "$body_file"
run_case gitlab_https 0 \
    'https://gitlab.com/owner/repo.git' glab \
    mr create --source-branch track/demo --target-branch main --title Demo --description-file "$body_file"
run_fallback 'https://forge.example/owner/repo.git' 'forge.example'
run_fallback 'https://github.com/owner/repo.git' 'git push -u origin track/demo'
run_provider_failure github 'https://github.com/owner/repo.git'
run_body_failure 'https://github.com/owner/repo.git' "$work_dir/missing review.md"
mkdir "$work_dir/unreadable review.md"
run_body_failure 'https://github.com/owner/repo.git' "$work_dir/unreadable review.md"

cat >"$fake_bin/gh" <<'EOF'
#!/bin/sh
if [ "$1" = auth ] && [ "$2" = status ]; then exit "${GH_AUTH_STATUS:-0}"; fi
if [ "$1" = pr ] && [ "$2" = create ]; then
    printf '%s\n' "$@" >"$FAKE_LOG_DIR/gh"
    exit "${GH_CREATE_STATUS:-0}"
fi
exit 1
EOF
chmod +x "$fake_bin/gh"
run_missing_cli 'https://github.com/owner/repo.git'
run_auth_failure 'https://github.com/owner/repo.git'
run_glab_missing_cli 'https://gitlab.com/owner/repo.git'
run_glab_auth_failure 'https://gitlab.com/owner/repo.git'
run_glab_provider_failure 'https://gitlab.com/owner/repo.git'

printf 'PASS: open-pr dispatcher tests\n'
