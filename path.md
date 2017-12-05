---
tagline: path manipulation
---

## `local path = require'path'`

### API

------------------------------------------------ ------------------------------------------------
`path.platform -> s`                             get the current platform
`path.sep([pl]) -> s`                            get the default separator for a platform
`path.dev_alias(s) -> s`                         check if a path is a Windows device alias
`path.type(s, [pl]) -> type`                     get the path type
`path.parse(s, [pl]) -> type, path, drv|srv|nil` split path depending on type
`path.format(type, path, drv|srv) -> s`          put together a path
`path.separator(s, [pl], [which], [sep]) -> s`   get/add/set/detect the start/end/all separators
`path.common(p1, p2, [pl]) -> s`                 get the common prefix between two paths
`path.basename(s, [pl]) -> s`                    get the last component from a path
`path.extname(s, [pl]) -> s`                     get the filename extension from a path
`path.dirname(s, [pl]) -> s`                     get the path without basename
`path.abs(s, pwd) -> s`                          convert relative path to absolute
`path.rel(s, pwd) -> s`                          convert absolute path to relative
`path.normalize(s, [pl], [opt]) -> s`            normalize a path in various ways
`path.filename(s, [pl], [repl]) -> s`            validate/make-valid filename
------------------------------------------------ ------------------------------------------------

In the table above, `pl` is for platform and can be `'win'` or `'unix'` and
defaults to the current platform.

## `path.platform -> s`

Get the current platform which can be `'win'` or `'unix'`.

## `path.sep([pl]) -> s`

Get the default separator for a platform which can be `\\` or `/`.

## `path.dev_alias(s) -> s`

Check if a path is a Windows device alias and if it is, return that alias.

## `path.type(s, [pl]) -> type`

Get the path type which can be: `'abs'`, `'abs_long'`, `'abs_nodrive'`,
`'rel'`, `'rel_drive'`, `'unc'`, `'unc_long'`, `'global'`, `'dev'`,
`'dev_alias'`.

The empty path ('') comes off as type 'rel'.

The only paths that are portable between Windows and UNIX (Linux, OSX)
without translation are type `'rel'` paths using forward slashes only which
are no longer than 259 bytes and which don't contain any control characters
(code 0-31) or the symbols `<>:"|%?*\`.

## `path.parse(s, [pl]) -> type, path, drive|server|nil`

Split a path into its local path component and, depending on the path type,
the drive letter or server name.

UNC paths are not validated and can have and empty server or path.

## `path.format(type, path, drv|srv) -> s`

Put together a path from its broken-down components. No validation is done.

## `path.separator(s, [pl], [which], [sep]) -> s`

Get/add/set the start/end/all separators for a path or detect the separator
used everywhere on the path if any.

If `sep` is missing, and `which` is missing too or `which` is `'all'`,
the detected separator is returned, if any. Otherwise `which` can be
`'start'` or `'end'` to return the starting or ending separator, if any.
The starting, ending, or all separators can be changed if `sep` is given,
but only if a separator already existed at that position. To force-add
a starting or ending separator, `which` must be `'+start'` or `'+end'`.
If `sep` is `true` then the path's separator is used if it's detected,
otherwise the default platform separator is used.

Removing duplicate separators without normalizing the separators is possible
by passing `'%1'` to `sep`.

__NOTE:__ Setting '\' on a UNIX path may result in an invalid path because
`\` is a valid character in UNIX filenames!

__NOTE:__ Removing a separator on `/` makes the path relative!

__NOTE:__ Adding a separator to `''` (which is `'.'`) makes the path absolute!

## `path.common(p1, p2, [pl]) -> s`

Get the common prefix (including the end separator) between two paths.

## `path.basename(s, [pl]) -> s`

Get the last component from a path.
If the path ends in a separator then the empty string is returned.

## `path.extname(s, [pl]) -> s`

Get the filename extension from a path, if any.

## `path.dirname(s, [pl]) -> s`

Get the path without basename and separator. If the path ends in a separator
then the whole path without the separator is returned.

## `path.abs(s, pwd) -> s`

Convert a relative path to an absolute path given a base dir.

## `path.rel(s, pwd) -> s`

Convert an absolute path into relative path which is relative to `pwd`.

## `path.normalize(s, [pl], [opt]) -> s`

Normalize a path in various ways, depending on `opt`:

  *
  *

## `path.filename(s, [pl], [repl]) -> s`

Validate a filename or apply a replacement function/table/string on it in
order to make it valid.

