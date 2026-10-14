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
#   $PREFIX ($PASSWORD_STORE_DIR or default ~/.password-store)

# pass sources extensions from inside cmd_extension(), so top-level local as
# used here is valid.
# shellcheck disable=SC2168

#------------------------------------------------------------------------------
# cleanup
#------------------------------------------------------------------------------

set -u -o pipefail
trap cleanup INT ABRT SEGV PIPE TERM USR1 USR2


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
pass cl [-r <regex> | -l <lineno>] [-s] [-L | <entry>]
pass cl -o [-L | <entry>]

options:
    -r <regex> : select line containing <regex> for metadata, remove <regex>
                 from result
    -l <lineno>: instead of <regex>, copy metadata from line number <lineno>
    -s         : swap metadata ($meta_sel) and password ($pass_sel) selection
                 content
    -o         : shortcut for "pass otp --clip <entry>"
    -L         : use <entry> of the last "pass cl" call (cached in the
                 $cache_sel selection)
EOF
}


#------------------------------------------------------------------------------
# main
#------------------------------------------------------------------------------

meta_sel=${PASSWORD_STORE_X_SELECTION_META:-primary}
pass_sel=$X_SELECTION
# xclip only looks at the first character of the selection name.
cache_sel=secondary
[[ $meta_sel == s* || $pass_sel == s* ]] && \
    err "$cache_sel selection is used as cache for -L, can't use it for" \
        "PASSWORD_STORE_X_SELECTION(_META)=$pass_sel/$meta_sel"


local regex=
local lineno=
local swap_sels=false
local do_otp=false
local use_last=false
local nopts=0
local path=
while getopts r:l:soLh opt; do
    nopts=$((nopts + 1))
    case $opt in
        r) regex="$OPTARG";;
        l) lineno="$OPTARG";;
        s) swap_sels=true;;
        o) do_otp=true;;
        # -L only selects the entry, so it may be combined with -o
        L) use_last=true; nopts=$((nopts - 1));;
        h) usage; exit 0;;
        \?) exit 1;;
    esac
done
shift $((OPTIND - 1))

# Early option checks before possible fzf
[ -n "$lineno" ] && [ -n "$regex" ] && err "use either -r or -l"
$do_otp && [ "$nopts" -gt 1 ] && \
    err "-o cannot be combined with other options (except -L)"

if $use_last; then
    [ $# -eq 0 ] || err "-L cannot be combined with <entry>"
    # The cache never expires, which is fine since it is only path/to/entry so
    # no sensitive info per se. Sill, if we want to change that, we'd need to
    # use/reimplement pass' 45 seconds ($CLIP_TIME) subshell + sleeper process
    # machinery.
    path=$(xclip -o -sel $cache_sel 2>/dev/null)
elif [ $# -eq 0 ]; then
    # `pass git ls-files` breaks unicode, e.g. fjällräven becomes
    # "fj\303\244llr\303\244ven.gpg", that's why we use find
    path=$(find $PREFIX -name "*.gpg" \
        | sed -nre "s|$PREFIX/(.+).gpg|\\1|p" \
        | fzf -e --height=~20%)
else
    [ $# -eq 1 ] || err "need exactly one argument"
    path="$1"
fi

[ -n "$path" ] || err "no entry selected or cached"
echo "$path" | xclip -i -sel $cache_sel > /dev/null 2>&1 \
    || err "could not store entry in $cache_sel selection"

if $do_otp; then
    pass otp --clip "$path"
    exit $?
fi

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
