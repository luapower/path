---
tagline: path manipulation
---

## `local path = require'path'`

Path manipulation library for Windows and UNIX spaths. Parses all Windows
path formats including long paths (`\\?\`), device paths (`\\.\`)
and UNC paths.

### API

------------------------------------------------ ------------------------------------------------
`path.platform -> s`                             get the current platform
`path.sep([pl]) -> s`                            get the default separator for a platform
`path.dev_alias(s) -> s`                         check if a path is a Windows device alias
`path.type(s, [pl]) -> type`                     get the path type
`path.parse(s, [pl]) -> type, path[, drv|srv]    split path depending on type
`path.format(type, path, [drv|srv]) -> s`        put together a path
`path.isabs(s, [pl]) -> is_abs, is_empty`        check if path is absolute and if it's empty
`path.endsep(s, [pl], [sep]) -> s, success`      get/add/remove ending separator
`path.separator(s, [pl], [which], [sep]) -> s`   get/add/set/detect the start/end/all separators
`path.commonpath(p1, p2, [pl]) -> s`             get the common base path between two paths
`path.basename(s, [pl]) -> s`                    get the last component from a path
`path.dirname(s, [pl]) -> s`                     get the path without basename
`path.splitext(s, [pl]) -> name, ext`            split path's filename into name and extension
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

Get the path type which can be:

* `'abs'` - `C:\path` (Windows) or `/path` (UNIX)
* `'abs_long'` - `\\?\C:\path` (Windows)
* `'abs_nodrive'` - `\path` (Windows)
* `'rel'` - `a\b`, `a/b`, `''`, etc. (Windows, UNIX)
* `'rel_drive'` - `C:a\b` (Windows)
* `'unc'` - `\\server\share\path` (Windows)
* `'unc_long'` - `\\?\UNC\server\share\path` (Windows)
* `'global'` - `\\?\path` (Windows)
* `'dev'` - `\\.\path` (Windows)
* `'dev_alias'`: `CON`, `c:\path\nul.txt`, etc. (Windows)

The empty path (`''`) comes off as type `'rel'`.

The only paths that are portable between Windows and UNIX (Linux, OSX)
without translation are type `'rel'` paths using forward slashes only which
are no longer than 259 bytes and which don't contain any control characters
(code 0-31) or the symbols `<>:"|%?*\`.

## `path.parse(s, [pl]) -> type, path[, drive|server]`

Split a path into its local path component and, depending on the path type,
the drive letter or server name.

UNC paths are not validated and can have and empty server or path.

## `path.format(type, path, [drive|server]) -> s`

Put together a path from its broken-down components. No validation is done.

## `path.isabs(s, [pl]) -> is_abs, is_empty`

Check if a path is an absolute path or not, and if it's empty or not.

__NOTE:__ Absolute paths for which their local path is `''` are actually
invalid (currently only incomplete UNC paths like `\\server` or `\\?` can be
like that) but the function doesn't check for that specifically.

## `path.endsep(s, [pl], [sep]) -> s, success`

Get/add/remove an ending separator. The arg `sep` can be `nil`, `true`,
`false`, `'\\'`, `'/'`, `''`: if `sep` is `nil` or missing, the ending
separator is returned (nil if missing), otherwise it is added or removed
(`true` means detect separator to use, `false` means `''`). `success`
is `false` if trying to add an ending slash to an empty relative path or
trying to remove it from an absolute empty path, which are not allowed.

## `path.separator(s, [pl], [sep]) -> s`

Detect or set the a path's separator (for Windows paths only).

The arg `sep` can be `nil`, `true` (platform default), `'\\'`, `'/'`,
or `1` (remove duplicate separators without normalizing them).

__NOTE:__ Setting the separator as `\` on a UNIX path may result in an
invalid path because `\` is a valid character in UNIX filenames.

## `path.commonpath(p1, p2, [pl]) -> s`

Get the common base path (including the end separator) between two paths.

## `path.basename(s, [pl]) -> s`

Get the last component from a path.
If the path ends in a separator then the empty string is returned.

## `path.dirname(s, [pl]) -> s`

Get the path without basename and separator. If the path ends in a separator
then the whole path without the separator is returned.

## `path.splitext(s, [pl]) -> name, ext`

Split a path's filename into the name and extension parts like so:

* `a.txt'` -> `'a'`, `'txt'`
* `'.bashrc'' -> `'.bashrc'`, `nil`
* `a'` -> `'a'`, `nil`
* `'a.'` -> `'a'`, `''`

## `path.abs(s, pwd) -> s`

Convert a relative path to an absolute path given a base dir.

## `path.rel(s, pwd) -> s`

Convert an absolute path into relative path which is relative to `pwd`.

## `path.normalize(s, [pl], [opt]) -> s`

Normalize a path in various ways, depending on `opt`:

  * `dot_dirs`
  * `dot_dot_dirs`
  *

## `path.filename(s, [pl], [repl]) -> s`

Validate a filename or apply a replacement function/table/string on it in
order to make it valid.

