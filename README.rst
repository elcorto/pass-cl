pass cl
=======

An extension for `password-store <https://www.passwordstore.org>`_ that copies
metadata into the primary X selection (middle mouse button).

password-store proposes a multi-line format in which the password is on the
first line and arbitrary metadata on the following lines. A typical password
file (``$PASSWORD_STORE_DIR/foo.gpg``) would look like this:

::

    passzzwoo00rrd11!!1!!
    user@foo.com
    meta:bar
    more meta=baz

where the second line could be the login name.

A common use case is to copy the first line (the password) using ``pass -c
foo`` into Clipboard. The default from ``pass insert foo`` results in a
one-line file, so ``pass`` always copies the first line. Everything beyond the
first line (metadata) is ignored. It can only be displayed with another ``pass
foo``.

Usage
-----

.. code-block:: sh

    $ pass cl foo

The default behavior is to copy the first line (password) to the Clipboard
(CTRL-V) as usual (like ``pass -c foo``). Additionally, the second line is
copied into Primary (middle mouse). See below for more on X selections.

Check:

.. code-block:: sh

    $ xclip -o -sel clip
    passzzwoo00rrd11!!1!!
    $ xclip -o -sel prim
    user@foo.com

If you have data on another line than the second or want to strip part of the
line, you can use the ``-r`` flag to provide a regex matching that line.

.. code-block:: sh

    $ pass cl -r meta: foo
    $ xclip -o -sel prim
    bar

The matching part of the line is removed, leaving only the metadata. Make sure
to use ``-r`` right after ``cl``, else ``pass``'s command line parser will
complain. Hint: avoid whitespaces in your metadata lines (``meta:bar`` instead
of ``meta : bar``) to keep the regex simple. In the last example we would need
``-r 'meta\s+:\s+'`` to match all whitespaces since we want the complete match
to be removed, leaving only ``bar`` without any whitespace.

``pass`` copies the password to Clipboard. If you need to paste this in a shell
where you cannot use CTRL-V (e.g. XTerm), you can copy it to Primary with plain
``pass`` like so:

.. code-block:: sh

    $ PASSWORD_STORE_X_SELECTION=primary pass -c foo

and paste that in the shell (or anywhere else) with Shift-Insert, which always
pastes Primary only. With ``pass cl``, you can use the ``-s`` option to swap
the content of Primary and Clipboard to have the password in Primary.

.. code-block:: sh

    $ pass cl -s foo

Check:

.. code-block:: sh

    $ xclip -o -sel clip
    user@foo.com
    $ xclip -o -sel prim
    passzzwoo00rrd11!!1!!
    $ <Shift-Insert>
    passzzwoo00rrd11!!1!!


Installation
------------

.. code-block:: sh

    $ export PASSWORD_STORE_ENABLE_EXTENSIONS=true
    $ export PASSWORD_STORE_EXTENSIONS_DIR=$HOME/.pass_extensions
    $ mkdir -p $PASSWORD_STORE_EXTENSIONS_DIR
    $ ln -s $(pwd)/cl.bash $PASSWORD_STORE_EXTENSIONS_DIR/cl.bash


X selections
------------

There are different X selections (see ``xclip -selection``):

* "primary" = `XA_PRIMARY` (default in xclip, use middle mouse to paste)
* "secondary = `XA_SECONDARY` (usually not used)
* "clipboard" = `XA_CLIPBOARD` (CTRL-V to paste in most GUI apps)

See also `xclip-dump.sh <https://github.com/elcorto/shelltools/blob/master/bin/xclip-dump.sh>`_.
