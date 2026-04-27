#!/bin/bash

# pass extension
#
# This script gets sourced in /path/to/password-store/src/password-store.sh.
# Therefore, we can use several functions and vars defined in there, such as
#
#   die()
#   check_sneaky_paths()
#   $X_SELECTION
#   $GPG
#   $GPG_OPTS

# pass sources extensions from inside cmd_extension(), so top-level local as
# used here is valid.
# shellcheck disable=SC2168

#------------------------------------------------------------------------------
# cleanup
#------------------------------------------------------------------------------

set -u -o pipefail
trap cleanup INT ABRT KILL SEGV PIPE TERM STOP USR1 USR2


#------------------------------------------------------------------------------
# functions
#------------------------------------------------------------------------------

err(){
    die "error: pass cl: $@"
}


xclip_store_meta(){
    xclip -i -sel $meta_sel > /dev/null 2>&1
    [ $? -eq 0 ] || err "xclip_store_meta failed"
}


get_meta(){
    local start=2
    [ $# -eq 1 ] && start=$1
    tail -n +$start
}


cleanup(){
    unset content pass
}


usage(){
    cat << EOF
    pass cl [-r <regex> | -l <lineno>] [-s] <entry>
    pass cl -o <entry>

options:
    -r <regex> : select line containing <regex> for metadata, remove <regex>
                 from result
    -l <lineno>: instead of <regex>, copy metadata from line number <lineno>
    -s         : swap metadata ($meta_sel) and password ($pass_sel) selection
                 content
    -o         : shortcut for "pass otp --clip <entry>"
EOF
}


#------------------------------------------------------------------------------
# main
#------------------------------------------------------------------------------

meta_sel=${PASSWORD_STORE_X_SELECTION_META:-primary}
pass_sel=$X_SELECTION


local regex=
local lineno=
local swap_sels=false
local do_otp=false
local nopts=0
while getopts r:l:soh opt; do
    nopts=$((nopts + 1))
    case $opt in
        r) regex="$OPTARG";;
        l) lineno="$OPTARG";;
        s) swap_sels=true;;
        o) do_otp=true;;
        h) usage; exit 0;;
        \?) exit 1;;
    esac
done
shift $((OPTIND - 1))


if $do_otp; then
    [ "$nopts" -gt 1 ] && err "-o cannot be combined with other options"
    pass otp --clip "$@"
    exit $?
fi

[ $# -ge 1 ] || err "missing argument"
[ -n "$lineno" ] && [ -n "$regex" ] && err "use either -r or -l"


local path="$1"
local passfile="$PREFIX/$path.gpg"
[ -f "$passfile" ] || err "$path is not in the password store"


check_sneaky_paths "$path"
content=$($GPG -d "${GPG_OPTS[@]}" "$passfile")
nlines=$(echo "$content" | wc -l)

if [ $nlines -gt 1 ]; then
    pass=$(echo "$content" | head -n1)
    if [ -n "$regex" ]; then
        meta=$(echo "$content" | get_meta | grep -E -m1 "$regex") || \
            err "regex '$regex' doesn't match"
        echo "$meta" | sed -E "s/$regex//" | xclip_store_meta \
            || err "could not copy metadata with regex '$regex', exit $?"
    elif [ -n "$lineno" ]; then
        echo "$content" | get_meta $lineno | head -n1 | xclip_store_meta || \
            err "could not copy metadata from line number $lineno, exit $?"
    else
        echo "$content" | get_meta | head -n1 \
            | xclip_store_meta || err "could not copy metadata from 2nd line, exit $?"
    fi
    echo "Copied metadata to $meta_sel selection."
else
    pass="$content"
fi

clip "$pass" "$path"

if $swap_sels; then
    meta_content=$(xclip -o -sel $meta_sel)
    xclip -o -sel $pass_sel | xclip -i -sel $meta_sel
    echo "$meta_content" | xclip -i -sel $pass_sel
    echo "Swapped selction $pass_sel <-> $meta_sel"
fi

cleanup
