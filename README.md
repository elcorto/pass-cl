# About

An extension for [password-store](https://www.passwordstore.org) that
copies the password and additional metadata (e.g. login name) into
separate X selections.

Defaults:

* password: `PASSWORD_STORE_X_SELECTION=clipboard` (default in `pass`), paste
  with `CTRL-V` (most GUIs) or `CTRL-Shift-V` (most shells)
* metadata: `PASSWORD_STORE_X_SELECTION_META=primary` (this extension), paste
  with middle mouse button or `Shift-Insert`

See below for more on X selections.

`pass insert foo` creates a one-line password file
`$PASSWORD_STORE_DIR/foo.gpg`, whose decrypted content is the password:

```
passzzwoo00rrd11!!1!!
```

A common use case is to copy this using `pass show -c foo` (or just
`pass -c foo`, `show` is default) into the Clipboard X selection.

`pass` also supports multiple lines (`pass insert -m foo`) in which the
password is on the first line (or any other with
`pass -c <line_number> foo`) and arbitrary metadata on the other lines.
A typical entry would look like this:

```
passzzwoo00rrd11!!1!!
user@foo.com
meta:bar
more meta=baz
otherstuff
```

where the second line could be the login name. However, everything
except the password line is ignored by `pass -c`. It can only be
displayed with another `pass foo` and copied manually if needed. This
extension additionally copies the second line (by default) to another X
selection (`PASSWORD_STORE_X_SELECTION_META`).

# Usage

```sh
$ pass cl foo
```

The default behavior is to copy the first line (password) to the Clipboard as
usual (like `pass -c foo`, paste with `CTRL-V` or `CTRL-Shift-V`).
Additionally, the second line is copied into the Primary selection
(`Shift-Insert` or middle mouse button to paste). We can use the `xclip` tool
to check what we copied into which selection.

```sh
$ xclip -o -sel clip
passzzwoo00rrd11!!1!!
$ xclip -o -sel prim
user@foo.com
```

The typical workflow is thus `pass cl foo`, go to where credentials need
to be inserted (e.g. the browser), middle mouse -\> login, `CTRL-V` -\>
password.

## Select a metadata line

If you want to copy metadata from another line than the second, you can
use `-l <line_number>`.

```sh
$ pass cl -l5 foo
$ xclip -o -sel prim
otherstuff
```

Alternatively, you can use the `-r` option to provide a regex matching
that line.

```sh
$ pass cl -r meta: foo
$ xclip -o -sel prim
bar
```

The matching part of the line is removed, leaving only the metadata.
This is useful for selecting lines by prefix (such as `meta:`). Hint:
avoid whitespaces in your metadata lines (`meta:bar` instead of
`meta : bar`) to keep the regex simple. In the last example we would
need `-r 'meta\s+:\s+'` to match all whitespaces since we want the
complete match to be removed, leaving only `bar` without any whitespace.

## Swap selection content

`pass show` copies the password to Clipboard. If you need to paste this
in a weird shell where not even `CTRL-Shift-V` works, then you can copy it to
Primary instead with plain `pass` like so:

```sh
$ PASSWORD_STORE_X_SELECTION=primary pass -c foo
```

and paste that in the shell or anywhere else with `Shift-Insert` or the
middle mouse button. With `pass cl`, you can use the `-s` flag to swap
the content of Primary and Clipboard to have the password in Primary.

```sh
$ pass cl -s foo
```

Check:

```sh
$ xclip -o -sel clip
user@foo.com
$ xclip -o -sel prim
passzzwoo00rrd11!!1!!
$ <Shift-Insert>
passzzwoo00rrd11!!1!!
```

## pass compatibility

Make sure to place this extension\'s options right after `cl`

```sh
$ pass cl [options] foo
```

else `pass`\'s command line parser will complain.

We do not support any options of `pass show` such as
`-c|--clip [<line_number>]` or `-q|--qrcode [<line_number>]`. For
instance these won\'t work

```sh
$ pass cl -c [<line_number>] foo    # error
$ pass cl foo -c [<line_number>]    # ignored
```

If you want to use those, please use `pass show` directly and deal with
metadata in another way. Here, the password is always copied from the
first line.

# Installation

```sh
$ export PASSWORD_STORE_ENABLE_EXTENSIONS=true
$ export PASSWORD_STORE_EXTENSIONS_DIR=$HOME/.pass_extensions
$ mkdir -p $PASSWORD_STORE_EXTENSIONS_DIR
$ ln -s $(pwd)/cl.bash $PASSWORD_STORE_EXTENSIONS_DIR/cl.bash
```

# X selections

There are different X selections (see `xclip -selection`). If you never heard
of those, then you are probably familiar with at least "the clipboard",
`CTRL-C` to copy, `CTRL-V` to paste. Well, in X, we have 3.

* primary: default in xclip, what gets filled when you highlight stuff with the
  mouse cursor
* secondary: usually not used
* clipboard: the system clipboard you know from other systems

See also [xclip-dump](https://github.com/elcorto/shelltools/blob/master/bin/xclip-dump).
