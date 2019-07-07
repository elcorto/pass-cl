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


do_xclip(){
    xclip -sel $meta_sel > /dev/null 2>&1
    [ $? -eq 0 ] || err "xclip selection failed"
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
    pass cl [-r <regex> | -l <lineno> ] [-s] <entry>

options:
    -r <regex> : select line containing <regex> for metadata, remove <regex>
                 from result
    -l <lineno>: instead of <regex>, copy metadata from line number <lineno>
    -s         : swap primary and clipboard selection content
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
[ -f $passfile ] || err "$path is not in the password store"


check_sneaky_paths "$path"
content=$($GPG -d "${GPG_OPTS[@]}" "$passfile")
nlines=$(echo "$content" | wc -l)

if [ $nlines -gt 1 ]; then
    pass=$(echo "$content" | head -n1)
    if [ -n "$regex" ]; then
        meta=$(echo "$content" | get_meta | grep -E -m1 "$regex") || \
            err "regex '$regex' doesn't match"
        echo "$meta" | sed -E "s/$regex//" | do_xclip \
            || err "could not copy metadata with regex '$regex', exit $?"
    elif [ -n "$lineno" ]; then
        echo "$content" | get_meta $lineno | head -n1 | do_xclip || \
            err "could not copy metadata from line number $lineno, exit $?"
    else
        echo "$content" | get_meta | head -n1 \
            | do_xclip || err "could not copy metadata from 2nd line, exit $?"
    fi
    echo "Copied metadata to primary selection."
else
    pass="$content"
fi

clip "$pass" "$path"

if $swap_sels; then
    prim=$(xclip -o -sel prim)
    xclip -o -sel clip | xclip -i -sel prim
    echo "$prim" | xclip -i -sel clip
fi

cleanup
