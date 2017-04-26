# pass pclip

An extension for [password store](https://www.passwordstore.org/) that copies meta data into the primary clipboard (middle mouse button).

[password store](https://www.passwordstore.org/) proposes a format to store meta data in the password file. The password is stored in the first line followed by  data like the URL, username and other meta data in the following lines. A common password file would like this:
```
Yw|ZSNH!}z"6{ym9pI
URL: *.amazon.com/*
Username: AmazonianChicken@example.com
```

A common use case is to copy the first line (the password) using `pass show -c <password file>`.

The meta data usually cannot be copied but needs to be displayed.

## Usage
```
pass pclip <password file>
```
The default behavior is to copy the second line (line after password) into the primary clipboard. If you would like to use a more flexible schema as shown above you can set `PASS_PCLIP_KEY`. Example:
```
export PASS_PCLIP_KEY='^Username:\s?'
```

## Installation

- Enable password-store extensions by setting ``PASSWORD_STORE_ENABLE_EXTENSIONS=true``
- Add `pclip.bash` in `~/password-store/.extensions` and make it executable

## Contribution

Contributions are always welcome.
