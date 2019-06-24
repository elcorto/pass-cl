#!/bin/bash

set -u -o pipefail

err(){
    die "error: pass cl: $@"
}

do_xclip(){
    # Some versions of xclip seem to have a -r flag. Ours doesn't (Debian).
    stdin=$(cat)
    echo "$stdin" | xclip -sel prim > /dev/null 2>&1
    [ $? -eq 0 ] || echo "$stdin" | xclip -r > /dev/null 2>&1
    [ $? -eq 0 ] || err "xclip failed"
}

get_meta(){
    local start=2
    [ $# -eq 1 ] && start=$1
    local tmp=$($GPG -d "${GPG_OPTS[@]}" "$passfile")
    if [ $start -gt $(echo "$tmp" | wc -l) ]; then
        unset tmp
        err "line number $lineno beyond end of file"
    fi
    echo "$tmp" | tail -n +$start
    unset tmp
}

usage(){
    cat << EOF
    pass cl [-r <regex> | -l <lineno> ] [-s] <entry>

options:
    -r <regex> : select line containing <regex> for metadata, remove <regex>
                 from result
    -l <lineno>: instead of <regex>, copy metadata from line number <lineno>
    -s         : swap primary and clipboard selection content
EOF
}

local regex=
local lineno=
local swap_sels=false
while getopts r:l:sh opt; do
    case $opt in
        r) regex="$OPTARG";;
        l) lineno="$OPTARG";;
        s) swap_sels=true;;
        h) usage; exit 0;;
        \?) exit 1;;
    esac
done
shift $((OPTIND - 1))

[ $# -ge 1 ] || err "missing argument"
[ -n "$lineno" ] && [ -n "$regex" ] && err "use either -r or -l"


local path="$1"
local passfile="$PREFIX/$path.gpg"

check_sneaky_paths "$path"

if [ -f $passfile ]; then
    if [ -n "$regex" ]; then
        meta=$(get_meta | grep -E -m1 "$regex") || err "regex '$regex' doesn't match"
        echo "$meta" | sed -E "s/$regex//" | do_xclip \
            || err "could not copy metadata with regex '$regex', exit $?"
    elif [ -n "$lineno" ]; then
        get_meta $lineno | head -n1 | do_xclip || \
            err "could not copy metadata from line number $lineno, exit $?"
    else
        get_meta | head -n1 \
            | do_xclip || err "could not copy metadata from 2nd line, exit $?"
    fi
    echo "Copied metadata to primary selection."
else
    err "Error: $path is not in the password store."
fi

cmd_show --clip "$@"

if $swap_sels; then
    prim=$(xclip -o -sel prim)
    xclip -o -sel clip | xclip -i -sel prim
    echo "$prim" | xclip -i -sel clip
fi
