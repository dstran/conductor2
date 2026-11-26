#!/bin/sh

# Contract: installation publishes the current lifecycle docs and Swift guide,
# is repeatable, and leaves unrelated agent configuration untouched.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/test-conductor-install.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_same() {
    cmp -s "$1" "$2" || fail "installed file differs or is missing: $2"
}

test_home="$work_dir/home with spaces"
run_dir="$work_dir/outside source"
config="$test_home/.config/opencode"
command_dir="$config/command/conductor"
mkdir -p "$run_dir" "$config/skills/unrelated"
printf 'keep this configuration\n' > "$config/skills/unrelated/sentinel"
sha=$(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || printf unknown)

for pass in first second; do
    if ! (
        cd "$run_dir"
        HOME="$test_home" bash "$repo_root/install.sh"
    ) > "$work_dir/install-$pass.log" 2>&1; then
        cat "$work_dir/install-$pass.log" >&2
        fail "$pass isolated install failed"
    fi

    assert_same "$repo_root/skill/SKILL.md" "$config/skills/conductor/SKILL.md"
    for command in setup new-track implement review; do
        assert_same "$repo_root/.opencode/command/$command.md" \
            "$command_dir/$command.md"
    done
    assert_same "$repo_root/conductor/assets/code_styleguides/swift.md" \
        "$command_dir/assets/code_styleguides/swift.md"
    assert_same "$repo_root/conductor/scripts/open-pr.sh" \
        "$command_dir/assets/scripts/open-pr.sh"
    assert_same "$repo_root/conductor/scripts/archive-track.py" \
        "$command_dir/assets/scripts/archive-track.py"

    # The only installed template difference is the installer-added version.
    template="$command_dir/assets/workflow-template.md"
    [ -f "$template" ] || fail 'workflow template missing'
    sed '$d' "$template" > "$work_dir/template-body"
    assert_same "$repo_root/conductor/assets/workflow-template.md" \
        "$work_dir/template-body"
    [ "$(tail -n 1 "$template")" = "<!-- conductor-workflow-version: $sha -->" ] \
        || fail 'workflow template version marker missing or incorrect'

    [ "$(cat "$config/skills/unrelated/sentinel")" = 'keep this configuration' ] \
        || fail 'unrelated configuration changed'
    [ ! -e "$config/skills/impeccable" ] \
        || fail 'Conductor installer unexpectedly installed Impeccable'
    if grep -i 'impeccable' "$work_dir/install-$pass.log" >/dev/null; then
        fail 'installer output unexpectedly claims an Impeccable action'
    fi

    if [ "$pass" = first ]; then
        # Reinstallation must refresh owned files, not retain stale commands.
        printf 'stale\n' > "$command_dir/stale.md"
        printf 'corrupted\n' > "$command_dir/assets/code_styleguides/swift.md"
    else
        [ ! -e "$command_dir/stale.md" ] || fail 'stale owned command survived reinstall'
    fi
done

printf 'PASS: isolated installer publishes lifecycle and Swift assets, preserves unrelated config, and reinstalls cleanly\n'
