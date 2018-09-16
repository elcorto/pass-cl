# pass cl

An extension for [password store](https://www.passwordstore.org/) that copies
metadata into the primary X selection (middle mouse button). 

[password store](https://www.passwordstore.org/) proposes a format to store
metadata in the password file. The password is stored in the first line
followed by data such as the URL, username and other metadata in the following
lines. A common password file would like this:

```
passzzwoo00rrd11!!1!!
URL: foo.com
Username: user@foo.com
```

A common use case is to copy the first line (the password) using `pass -c foo`
from the file `$PASSWORD_STORE_DIR/foo.gpg`. However, the metadata, i.e.
everything beyond the first line, is not copied. It can only be displayed with
another `pass foo`.

## Usage

```sh
pass cl foo
```
The default behavior is to copy the second line (line after password) into the
primary selection. The first line (password) is copied to the clipboard
selection as usual. See below for more on X selections.

If you have data on another line than the second, you can use the `-r` flag
to provide a regex matching that line.

```sh
pass cl -r '^Username:\s?' foo
```

The matching part of the line is removed, leaving only the metadata. Make sure
to use `-r` right after `cl`, else `pass`'s command line parser will
complain.

## Installation

- Enable password-store extensions by setting ``PASSWORD_STORE_ENABLE_EXTENSIONS=true``
- Add `cl.bash` in `~/.password-store/.extensions` and make it executable

The default extensions location is `$HOME/.password-store/.extensions`, which
is not ideal since that makes the extensions dir part of the password git repo
(in which case you want to `.gitignore` that). We suggest instead to use a
separate dir. You may also link to the git repo of this extension instead of
copying.

```sh
$ export PASSWORD_STORE_EXTENSIONS_DIR=$HOME/.pass_extensions
$ mkdir -p $PASSWORD_STORE_EXTENSIONS_DIR
$ ln -s $(pwd)/cl.bash $PASSWORD_STORE_EXTENSIONS_DIR/cl.bash 
```

## X selections

There are different X selections (see `xclip -selection`):

* "primary" = `XA_PRIMARY` (default in xclip, use middle mouse to paste)
* "secondary = `XA_SECONDARY` (usually not used)
* "clipboard" = `XA_CLIPBOARD` (CTRL-V to paste in most GUI apps)

See also [xclip-dump.sh](https://github.com/elcorto/shelltools/blob/master/bin/xclip-dump.sh).

## Contribution

Contributions are always welcome.
