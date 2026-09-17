#!/bin/sh

set -eu

fallback() {
    printf '%s\n' "Unable to create review request for ${host:-unknown host}: push the branch manually with git push -u origin $source"
    exit 1
}

[ "$#" -eq 4 ] || exit 1

source=$1
target=$2
title=$3
body_file=$4

[ -f "$body_file" ] && [ -r "$body_file" ] || exit 1

host=
remote=
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
    github.com)
        command -v gh >/dev/null 2>&1 || fallback
        gh auth status >/dev/null 2>&1 || fallback
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
