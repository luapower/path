
--path manipulation for Windows and UNIX paths
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'path_test'; return end

local path = {}
setmetatable(path, path)

path.platform = package.config:sub(1, 1) == '\\' and 'win' or 'unix'

local function win(pl) --check if pl (or current platform) is Windows
	if pl == nil then pl = path.platform end
	assert(pl == 'unix' or pl == 'win', 'invalid platform')
	return pl == 'win'
end

function path.sep(pl)
	return win(pl) and '\\' or '/'
end

local path_t = {}
path_t.__index = path_t

function path_t.copy(t)
	return setmetatable({
		type = t.type,
		platform = t.platform,
		path = t.path,
		drive = t.drive,
		server = t.server,
	}, path_t)
end

--device aliases are file names that are found _in any directory_.
local dev_aliases = {
	CON=1, PRN=1, AUX=1, NUL=1,
	COM1=1, COM2=1, COM3=1, COM4=1, COM5=1, COM6=1, COM7=1, COM8=1, COM9=1,
	LPT1=1, LPT2=1, LPT3=1, LPT4=1, LPT5=1, LPT6=1, LPT7=1, LPT8=1, LPT9=1,
}

--check if a path refers to a device alias and return that alias.
function path.dev_alias(s)
	s = s:match'[^\\/]+$' --basename (dev aliases are present in all dirs)
	s = s and s:match'^[^%.]+' --strip extension (they can have any extension)
	s = s and s:upper() --they're case-insensitive
	return s and dev_aliases[s] and s
end

--get the path type which can be: 'abs', 'abs_long', 'abs_nodrive',
--  'rel', 'rel_drive', 'unc', 'unc_long', 'global', 'dev', 'dev_alias'.
--NOTE: the empty path ('') comes off as type 'rel'.
function path.type(s, pl)
	if win(pl) then
		if s:find'^\\\\' then
			if s:find'^\\\\%?\\' then
				if s:find'^\\\\%?\\%a:\\' then
					return 'abs_long'
				elseif s:find'^\\\\%?\\[uU][nN][cC]\\' then
					return 'unc_long'
				else
					return 'global'
				end
			elseif s:find'^\\\\%.\\' then
				return 'dev'
			else
				return 'unc'
			end
		elseif path.dev_alias(s) then
			return 'dev_alias'
		elseif s:find'^%a:' then
			return s:find'^..[\\/]' and 'abs' or 'rel_drive'
		else
			return s:find'^[\\/]' and 'abs_nodrive' or 'rel'
		end
	else
		return s:find'^/' and 'abs' or 'rel'
	end
end

--split a path into its local path component and, depending on the path
--type, the drive letter or server name.
--NOTE: UNC paths are not validated and can have and empty server or path.
function path.parse(s, pl)
	local type = path.type(s, pl)
	if win(pl) and (type == 'abs' or type == 'rel_drive') then
		return type, s:sub(3), s:sub(1,1) -- \path, drive
	elseif type == 'abs_long' then
		return type, s:sub(3+4), s:sub(1+4,1 +4) -- \path, drive
	elseif type == 'unc' then
		local server, path = s:match'^..([^\\]*)(.*)$'
		return type, path, server
	elseif type == 'unc_long' then
		local server, path = s:match'^........([^\\]*)(.*)$'
		return type, path, server
	elseif type == 'dev' then
		return type, s:sub(4) -- \path
	elseif type == 'dev_alias' then
		return type, path.dev_alias(s) -- CON, NUL, ...
	elseif type == 'global' then
		return type, s:sub(4) -- \path
	else --type rel, abs_nodrive, abs/unix (nothing to split)
		return type, s
	end
end

--put together a path from its broken-down components.
function path.format(type, path, drive, pl)
	if win(pl) and type == 'abs' or type == 'rel_drive' then
		return drive .. ':' .. path
	elseif type == 'abs_long' then
		return '\\\\?\\' .. drive .. ':' .. path
	elseif type == 'unc' then
		local path = '\\\\' .. drive .. path
	elseif type == 'unc_long' then
		return '\\\\?\\UNC\\' .. drive .. path
	elseif type == 'dev_alias' then
		return path
	elseif type == 'dev' then
		return '\\\\.' .. path
	elseif type == 'global' then
		return '\\\\?' .. path
	else --abs/unix, rel, abs_nodrive
		return path
	end
end

--check if a path is an absolute path or not, and if it's empty or not.
--NOTE: absolute paths for which their local path is '' are actually invalid
--(currently only UNC paths can be invalid and still parse); for those paths
--the second return value will be nil.
local function isabs(type, p, win)
	if type == 'rel' or type == 'rel_drive' or type == 'dev_alias' then
		return false, p == ''
	elseif p == '' then
		return true, nil --invalid absolute path
	else
		return true, p:find(win and '^[\\/]+$' or '^/+$') and true or false
	end
end
function path.isabs(s, pl)
	local type, p = path.parse(s, pl)
	return isabs(type, p, win(pl))
end

--determine a path's separator if possible.
local function detect_sep(p, win)
	if win then
		local fws = p:find'[^/]*/'
		local bks = p:find'[^\\/]*\\'
		if not fws == not bks then
			return nil --can't determine
		end
		return fws and '/' or '\\'
	else
		return '/'
	end
end

--get/add/remove ending separator.
function path.endsep(s, pl, sep)
	local win = win(pl)
	local type, p, drive = path.parse(s, pl)
	if sep == nil then
		return p:match(win and '[\\/]+$' or '/+$')
	else
		local _, isempty = isabs(type, p, win)
		if isempty then --refuse to change the ending slash on empty paths
			return s, false
		elseif sep == false or sep == '' then --remove it
			p = p:gsub(win and '[\\/]+$' or '/+$', '')
			return path.format(type, p, drive), true
		elseif p:find(win and '[\\/]$' or '/$') then --add it/already set
			return s, true
		else
			if sep == true then
				sep = detect_sep(p, win) or (win and '\\' or '/')
			end
			assert(sep == '\\' or sep == '/', 'invalid separator')
			p = p .. sep
			return path.format(type, p, drive), true
		end
	end
end

--detect or set the a path's separator (for Windows paths only).
--NOTE: setting '\' on a UNIX path may result in an invalid path because
--`\` is a valid character in UNIX filenames!
--TIP: remove duplicate separators without normalizing them with sep = '%1'.
function path.separator(s, pl, sep)
	local win = win(pl)
	local type, p, drive = path.parse(s, pl)
	if sep == nil then
		return detect_sep(p, win)
	else
		if sep == true then
			sep = win and '\\' or '/'
		elseif sep == 1 then
			sep = '%1'
		end
		assert(sep == '\\' or sep == '/' or sep == '%1', 'invalid separator')
		p = p:gsub(win and '([\\/])[\\/]*' or '(/)/*', sep)
		return path.format(type, p, drive)
	end
end

local function combinable(type1, type2)
	if type2 == 'rel' then -- C:/a/b + c/d -> C:/a/b/c/d
		return type1 ~= 'dev_alias'
	elseif type2 == 'rel_drive' then -- C:/a/b + C:c/d -> C:/a/b/c/d
		return type1 == 'abs' or type1 == 'abs_long'
	elseif type2 == 'abs_nodrive' then -- C:/a/b + /c/d -> C:/c/d
		return type1 == 'abs' or type1 == 'abs_long'
	end
end

--combine two paths if possible.
function path.combine(s1, s2, pl)
	local type1 = path.type(s1, pl)
	local type2 = path.type(s2, pl)
	if not combinable(type1, type2) then
		return nil, string.format('cannot append %s to %s path', type2, type1)
	elseif s2 == '' then
		return s1
	elseif type2 == 'rel' then
		return path.endsep(s1, pl, true) .. s2
	elseif type2 == 'rel_drive' then -- C:/a/b + C:d/e -> C:/a/b/d/e
		local type1, p1, drive1 = path.parse(s1)
		local type2, p2, drive2 = path.parse(s2)
		if drive1 ~= drive2 then
			return nil, 'drives are different'
		end
		return path.append(s1, p2, pl)
	elseif type2 == 'abs_nodrive' then -- C:/a/b + /d/e -> C:/d/e
		local type1, p1, drive1 = path.parse(s1)
		return path.format(type1, s2, drive1)
	end
end

--get the common base path (including the end separator) between two paths.
--BUG: the case-insensitive comparison doesn't work with utf8 paths!
function path.commonpath(s1, s2, pl)
	local win = win(pl)
	local t1, p1, d1 = path.parse(s1, pl)
	local t2, p2, d2 = path.parse(s2, pl)
	local t, p, d
	if #p1 <= #p2 then --pick the smaller/first path when formatting
		t, p, d = t1, p1, d1
	else
		t, p, d = t2, p2, d2
	end
	if win then --make the search case-insensitive and normalize separators
		d1 = d1 and d1:lower()
		d2 = d2 and d2:lower()
		p1 = p1:lower():gsub('/', '\\')
		p2 = p2:lower():gsub('/', '\\')
	end
	if t1 ~= t2 or d1 ~= d2 or p1 == '' or p2 == '' then
		return path.format(t, '', d)
	end
	local sep = (win and '\\' or '/'):byte(1, 1)
	local si = 0 --index where the last common separator was found
	for i = 1, #p + 1 do
		local c1 = p1:byte(i, i)
		local c2 = p2:byte(i, i)
		local sep1 = c1 == nil or c1 == sep
		local sep2 = c2 == nil or c2 == sep
		if sep1 and sep2 then
			si = i
		elseif c1 ~= c2 then
			break
		end
	end
	p = p:sub(1, si)
	return path.format(t, p, d)
end

--get the last path component of a path.
--if the path ends in a separator then the empty string is returned.
function path.basename(s, pl)
	local _, p = path.parse(s, pl)
	return p:match(win(pl) and '[^\\/]*$' or '[^/]*$')
end

--get the filename without extension and the extension from a path.
function path.splitext(s, pl)
	local patt = win(pl) and '^(.-)%.([^%.\\/]*)$' or '^(.-)%.([^%./]*)$'
	local filename = path.basename(s, pl)
	local name, ext = filename:match(patt)
	if not name or name == '' then -- 'dir' or '.bashrc'
		name, ext = filename, nil
	end
	return name, ext
end

local function wrap(f)
	return function(s, pl, ...)
		local type, s, drive = path.parse(s, pl)
		s = f(s, pl, ...)
		return path.format(type, s, drive)
	end
end

local function wrap2(f)
	return function(s, arg, pl)
		local type, s, drive = path.parse(s, pl)
		s = f(s, arg, pl)
		return path.format(type, s, drive)
	end
end

--get a path without basename and separator. if the path ends with
--a separator then the whole path without the separator is returned.
path.dirname = wrap(function(s, pl)
	local i = s:match(win(pl) and '[\\/]*()[^\\/]*$' or '/*()[^/]*$')
	return s:sub(1, i-1)
end)

--transform a relative path into an absolute path given a base dir.
path.abs = wrap2(function(s, pwd, pl)
	local sep = path.sep(pl)
	return pwd .. sep .. s
end)

--transform an absolute path into a relative path which is relative to `pwd`.
path.rel = wrap2(function(s, pwd, pl)
	local win = win(pl)
	local prefix = path.commonpath(s, pwd, pl)
	--count the dir depth in pwd after the prefix.
	local pwd2 = pwd:sub(#prefix + 1)
	local n = 0
	for _ in pwd2:gmatch(win and '()[^\\/]+' or '()[^/]+') do
		n = n + 1
	end
	local s2 = s:sub(#prefix + 1)
	return ('../'):rep(n) .. s2
end)

--[[
-- remove duplicate separators (opt.separator = 1)
-- normalize the path separator (opt.separator = '/', '\', true)
-- add or set a specific ending slash (opt.dir_end = '\', '/')
-- add an ending slash if it's missing (opt.dir_end = true)
-- remove the ending slash (opt.dir_end = false)

-- remove any `.` dirs (opt.dot_dirs = false/nil)
-- remove unnecessary `..` dirs (opt.dot_dot_dirs = false/nil)

-- change the local path
-- change the server in UNC paths or make a path unc by specifying a server
-- change the drive or add a drive in Windows paths

-- convert between long and short Windows path encodings

]]
function path.normalize(s, pl, opt)
	opt = opt or {}
	local win = win(pl)
	local type, s, drive = path.parse(s, pl)

	--[[
	if opt.path then --change the local path and the path type accordingly
		local patt = win and '^[\\/]' or '^/'
		local rel1 = not s:find(patt)
		local rel2 = not opt.path:find(patt)
		if rel1 ~= rel2 then
			--TODO: change path type
		end
	end

	--add or change the drive and change path type accordingly
	if win and opt.drive then
		if type == 'abs_long' or type == 'abs' or type == 'rel_drive' then
			drive = opt.drive
		elseif type == 'abs_nodrive' then
			type, drive = 'abs', opt.drive
		elseif type == 'rel' then
			type, drive = 'rel_drive', opt.drive
		else
			type, drive = '', opt.drive
		end
	end

	--change the server or make path of unc type
	if win and opt.server then
		if type == 'unc' or type == 'unc_long' then
			drive = opt.server
		else
			type, drive = 'unc', opt.server
		end
	end
	]]

	--path separator options: nsep, rem_dsep
	local psep = win and '\\' or '/' --default platform sep
	local rem_dsep = opt.separator == 1 --remove duplicate seps
	local nsep = not rem_dsep and opt.separator --set specific sep
	if nsep then
		if nsep == true then --set to default
			nsep = psep
		elseif nsep ~= '\\' and
			(type == 'abs_long' or type == 'unc' or type == 'unc_long'
			or type == 'dev' or type == 'global')
		then
			nsep = '\\' --these path types don't support fw. slashes
		elseif not win and nsep ~= '/' then
			nsep = '/' --unix paths can only have '/'
		end
	end

	local function norm_sep(sep)
		if rem_dsep and #s > 1 then --remove dupe seps
			return sep:sub(1, 1)
		elseif nsep and #s > 0 then --set sep
			return nsep
		else
			return sep
		end
	end

	--ending slash options: esep, desep
	local esep = opt.dir_end --ending slash: true, false, s
	local desep = esep == true --ending slash when esep is true
		and (nsep or path.separator(s) or psep)

	--split the path and put it back together in a list.
	local t = {} --{dir1, sep1, ...}

	--add the root slash first or an empty string if the path is relative.
	local rsep = s:match(win and '^[\\/]*' or '^/*')
	table.insert(t, norm_sep(rsep))

	for s, sep in s:gmatch(win and '([^\\/]+)([\\/]*)' or '([^/]+)(/*)') do
		if not opt.dot_dirs and s == '.' then
			--skip adding the `.` dirs
		elseif not opt.dot_dot_dirs and s == '..' and #t > 0 then
			--find the last dir past any `.` dirs.
			local i = #t-1
			while t[i] == '.' do
				i = i - 2
			end
			--remove the last dir that's not `..` or the root element.
			if i > 1 and t[i] ~= '..' then
				table.remove(t, i)
				table.remove(t, i)
			end
		else
			table.insert(t, s)
			table.insert(t, norm_sep(sep))
		end
	end

	if rel_to then

	end

	if pwd and type == 'rel' or type == 'rel_drive' then

	end

	--apply dir_end option
	local sep = t[#t] --last separator, possibly empty
	if esep == false then --remove it...
		if #t == 1 and #sep > 1 then
			--path is `/` and removing that would make the path a relative path
			--so we just leave the `/` alone in this case.
		else
			t[#t] = ''
		end
	elseif esep then --leave it, add it or change it...
		local esep = esep
		if esep == true then --only add it if it's missing
			esep = sep == '' and desep or ''
		end
		if #t == 1 and sep == '' then
			--path is empty and adding `/` would make the path an absolute path
			--so we add a `.` in front to keep it relative.
			t[1] = '.'
			t[2] = esep --add it
		else
			t[#t] = esep --add it or change it
		end
	end

	return path.format(type, table.concat(t), drive, pl)
end


function path.gsplit(s, pl)
	return s:gmatch(win(pl) and '[^\\/]*' or '[^/]*')
end

--filename & pathname validation ---------------------------------------------

--validate/make-valid a filename
--NOTE: repl can be a function(match) -> repl_str.
--NOTE: if repl isn't itself escaped then duplicate filenames can result.
function path.filename(s, pl, repl)
	local win = win(pl)
	if s == '' then
		return nil, 'empty filename'
	end
	if s == '.' or s == '..' then
		if repl then
			return (s:gsub(s, repl))
		else
			return nil, 'filename is `' .. s .. '`'
		end
	end
	if win and path.dev_alias(s) then
		if repl then
			return (s:gsub(s, repl))
		else
			return nil, 'filename is a Windows device alias'
		end
	end
	local patt = win and '[%z\1-\31<>:"|%?%*\\/]' or '[%z/]'
	if repl then
		s = s:gsub(patt, repl)
	elseif s:find(patt) then
		return nil, 'invalid characters in filename'
	end
	if #s > 255 then --same maximum for Windows and Linux
		return nil, 'filename too long'
	end
	return s
end

function path.pathname(s, pl, repl)
	local t = {}
	for filename in path.gsplit(s, pl) do
		local name, err = path.filename(s, pl, repl)
		if err and not repl then
			return nil, err
		end
		t[#t+1] = name
	end
	return path.join(t, path.separator(s, pl) or path.separator(pl))
end


--[=[
--if allow_long and type == 'abs' and #path + 1 > 260 then
--if allow_long and #path + 1 > 260 then

local function not_win(path, drive)
	return
		path:find'[%z\1-\31<>:"|%?%*]'
			and 'invalid characters in Windows path'
		or (drive and not drive:find'^%a$')
			and 'invalid drive letter in Windows path'
end

local function not_unix(path)
	return path:find'%z' and 'invalid characters in UNIX path'
end

local function not_clean(path)
	return
		path:find'[%z\1-\31<>:"|%?%*]' --breaks Windows, Unix, bash
		or path:find' +$'  --deceiving
		or path:find'^ +'  --deceiving (removed silently in Windows)
		or path:find'%.+$' --removed silently in Windows
		or path:find'^%-+' --breaks bash
		or path:find'[%[]' --breaks bash
		and 'path contains evil characters'
end

local function not_global(path)
	return path:find'^\\' and [[invalid Windows \\?\ global path]]
end

local function not_abs_win(path)
	return path:find'^[\\/]' and [[not a Windows absolute path]]
end

local function not_abs_unix(path)
	return path:find'^/' and [[not a UNIX absolute path]]
end

--NOTE: we refuse `/`, `.` and `..` as filenames in \\?\ paths because
--they don't mean what they mean in normal paths which would make normal
--paths non-translatable to long paths.
local function not_abs_long(path)
	return
		path:find'/'
			and [[slash in \\?\ path]]
		or (path:find'\\%.\\' or path:find'\\%.$')
			and [[`.` pathname in Windows \\?\ path]]
		or (path:find'\\%.%.\\' or path:find'\\%.%.$')
			and [[`..` pathname in Windows \\?\ path]]
end

local function not_unc(path, server)
	return
		(server == '' or server:find'\\')
			and 'invalid server name for Windows UNC path'
		or not path:find'^\\[^\\/]+' --\share
			and 'invalid path for Windows UNC path'
end

local function not_length(too_long)
	return too_long and 'path too long'
end

local function validate(pl, type, path, drive)
	if win(pl) then
		if type == 'unc' then
			return not_unc(path, drive)
		elseif type == 'unc_long' then
			return not_unc(path, drive)
		elseif type == 'global' then
			return not_global(path)
		elseif type == 'dev' then
			return not_global(path)
		elseif type == 'abs' then
			return not_abs_win(path)
			local err = not_win(path, drive)
				or (type == 'abs' or type == 'abs_nodrive'
					and not_abs_win(path))
			if not err then
				err = not_length((drive and 2 or 0) + #path + 1 > 260)
				if allow_long_abs and err and type == 'abs' then
					err = not_abs_long(path)
				end
			end
			return err
		end
	else
		return not_unix(t.path)
			or not_length(#t.path > 256)
			or (t.type == 'abs' and not_abs_unix(t.path))
	end
end
function path.validate(s, pl)
	return validate(pl, path.parse(s, pl))
end

function path.isclean( allow_long_abs)
	return wrap_not(t,
		not_valid(t, allow_long_abs)
		or not_clean(t.path)
		or (t.server and not_clean(t.server)))
end

local function not_convertible(t, pl)
	local win = win(pl)
	pl = pl or path.platform
	if pl == t.platform then
		return
	end
	if t.type ~= 'rel' then
		return 'only relative paths are convertible'
	end
	if win then
		if t.path:find'\\' then --UNIX path has filenames with backslashes
			return 'invalid characters in Windows path'
		end
		return not_win(t.path), t.path
	else
		return not_unix(t.path:gsub('\\', '/'))
	end
end

function path_t.isconvertible(t, pl)
	return wrap_not(t, not_convertible(t, pl))
end

--convert path between platforms
function path_t.convert(t, pl)
	pl = pl or path.platform
	local win = win(pl)
	if pl == t.platform then
		return t
	end
	if t.type ~= 'rel' then
		return nil, 'only relative paths are convertible'
	end
	if win then
		if t.path:find'\\' then --UNIX path has filenames with backslashes
			return nil, 'invalid characters in Windows path'
		end
		local err = not_win(t.path)
		if err then return nil, err end
		t.platform = pl
	else
		local path = t.path:gsub('\\', '/')
		local err = not_unix(path)
		if err then return nil, err end
		t.path = path
		t.platform = pl
	end
	return t
end


]=]


return path

