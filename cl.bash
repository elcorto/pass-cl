#!/bin/bash

set -u -o pipefail

err(){
    die "pass cl: $@"
}

do_xclip(){
    # Some versions of xclip seem to have a -r flag. Ours doesn't (Debian).
    stdin=$(cat)
    echo "$stdin" | xclip -selection primary > /dev/null 2>&1
    [ $? -eq 0 ] || echo "$stdin" | xclip -r > /dev/null 2>&1
    [ $? -eq 0 ] || err "xclip failed"
    echo "Copied metadata to primary selection."
}

get_meta(){
    $GPG -d "${GPG_OPTS[@]}" "$passfile" | tail -n +2
}

local key=
while getopts r: opt; do
    case $opt in
        r)  key="$OPTARG";;
        \?) exit 1;;
    esac
done
shift $((OPTIND - 1))

[ $# -ge 1 ] || err "missing argument"
local path="$1"
local passfile="$PREFIX/$path.gpg"

check_sneaky_paths "$path"

if [ -f $passfile ]; then
    if [ -z "$key" ]; then
        get_meta | head -n1 \
            | do_xclip || err "could not copy metadata from 2nd line, exit $?"
    else
        meta=$(get_meta | grep -E -m1 "$key") || err "regex '$key' doesn't match"
        echo "$meta" | sed -E "s/$key//" | do_xclip \
            || err "could not copy metadata with regex '$key', exit $?"
    fi
else
    err "Error: $path is not in the password store."
fi

cmd_show --clip "$@"
