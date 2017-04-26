#!/bin/bash

local path="$1"
local passfile="$PREFIX/$path.gpg"
local key="${PASS_PCLIP_KEY}"

check_sneaky_paths "$path"

if [[ -f $passfile ]]; then
    if [[ -z "$key" ]]; then
        $GPG -d "${GPG_OPTS[@]}" "$passfile" | tail -n +2 | head -n1 | xclip -r || exit $?
    else
        $GPG -d "${GPG_OPTS[@]}" "$passfile" | tail -n +2 | grep -E -m1 "$key" | sed -E "s/$key//" | xclip -r || exit $?
    fi
elif [[ -z $path ]]; then
    die ""
else
    die "Error: $path is not in the password store."
fi

cmd_show --clip "$@"
