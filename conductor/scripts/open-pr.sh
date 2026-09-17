#!/bin/sh

set -eu

fallback() {
    case ${provider:-} in
        github)
            request_type='pull request'
            provider_name=GitHub
            ;;
        gitlab)
            request_type='merge request'
            provider_name=GitLab
            ;;
        *)
            request_type='pull request or merge request'
            provider_name='unsupported host'
            ;;
    esac
    printf '%s\n' "Unable to create review request for $provider_name on ${host:-unknown host}."
    printf '%s\n' 'Manual fallback:'
    printf '%s\n' "  git push -u origin $source"
    printf '%s\n' "  Open a $request_type manually on ${host:-unknown host} from $source into $target."
    exit 1
}

[ "$#" -eq 4 ] || exit 1

source=$1
target=$2
title=$3
body_file=$4

host=
remote=
provider=unsupported
if ! remote=$(git remote get-url origin 2>/dev/null); then
    fallback
fi

case $remote in
    git@*:* )
        remainder=${remote#git@}
        host=${remainder%%:*}
        path=${remainder#*:}
        ;;
    https://*/* )
        remainder=${remote#https://}
        host=${remainder%%/*}
        path=${remainder#*/}
        ;;
    *)
        fallback
        ;;
esac

[ -n "$host" ] && [ -n "$path" ] || fallback

case $host in
    github.com) provider=github ;;
    gitlab.com) provider=gitlab ;;
esac

[ -f "$body_file" ] && [ -r "$body_file" ] || fallback

case $host in
    github.com)
        command -v gh >/dev/null 2>&1 || fallback
        gh auth status --hostname github.com >/dev/null 2>&1 || fallback
        gh pr create --base "$target" --head "$source" \
            --title "$title" --body-file "$body_file" || fallback
        ;;
    gitlab.com)
        command -v glab >/dev/null 2>&1 || fallback
        glab auth status >/dev/null 2>&1 || fallback
        glab mr create --source-branch "$source" --target-branch "$target" \
            --title "$title" --description-file "$body_file" || fallback
        ;;
    *)
        fallback
        ;;
esac
