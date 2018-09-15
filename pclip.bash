#!/bin/bash

err(){
    die "pass pclip: $@"
}

do_xclip(){
    # Some versions of xclip seem to have a -r flag. Ours doesn't (Debian).
    stdin=$(cat)
    echo "$stdin" | xclip -selection primary > /dev/null 2>&1
    [ $? -eq 0 ] || echo "$stdin" | xclip -r > /dev/null 2>&1
    [ $? -eq 0 ] || err "xclip failed"
    echo "Copied metadata to primary selection."
}

local path="$1"
local passfile="$PREFIX/$path.gpg"
local key="${PASS_PCLIP_KEY}"

check_sneaky_paths "$path"

if [[ -f $passfile ]]; then
    if [[ -z "$key" ]]; then
        $GPG -d "${GPG_OPTS[@]}" "$passfile" | tail -n +2 | head -n1 \
            | do_xclip || err "could not copy metadata, exit $?"
    else
        $GPG -d "${GPG_OPTS[@]}" "$passfile" | tail -n +2 \
            | grep -E -m1 "$key" | sed -E "s/$key//" | do_xclip \
            || err "could not copy metadata, exit $?"
    fi
elif [[ -z $path ]]; then
    die ""
else
    err "Error: $path is not in the password store."
fi

cmd_show --clip "$@"
