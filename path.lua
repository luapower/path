
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

--get/add/set the start/end/all separators for a path or detect the separator
--used everywhere on the path if any.
--NOTE: setting '\' on a UNIX path may result in an invalid path because
--`\` is a valid character in UNIX filenames!
--NOTE: removing a separator on `/` makes the path relative!
--NOTE: adding a separator to '' (which is '.') makes the path absolute!
--NOTE: removing duplicate separators without normalizing the separators
--is possible by passing '%1' to sep.
path.separator = wrap(function(s, pl, which, sep)
	local win = win(pl)
	local psep = win and '\\' or '/'
	if which then
		local replace_only =
			which == 'start' or which == 'end' or which == 'all'
		local add_patt, repl_patt
		if which == 'start' or which == '+start' then
			add_patt  = win and '^([\\/]?)[\\/]*' or '^(/?)/*'
			repl_patt = win and '^([\\/])[\\/]*'  or '^(/)/*'
		elseif which == 'end' or which == '+end' then
			add_patt  = win and '([\\/]?)[\\/]*$' or '(/?)/*$'
			repl_patt = win and '([\\/])[\\/]*$'  or '(/)/*$'
		elseif which == 'all' then
			if not sep then --detect separator
				return path.separator(s, pl)
			elseif sep == true then --set to default, no point detecting it
				sep = psep
			end
			repl_patt = win and '([\\/])[\\/]*'  or '(/)/*'
		else
			error'invalid option'
		end
		if sep then --add/replace separator
			if sep == true then --detect separator or use platform's default
				sep = path.separator(s, pl) or psep
			end
			if replace_only then
				return (s:gsub(repl_patt, sep))
			elseif which == '+end' then
				--NOTE: we use both patterns here because the pattern '/*$'
				--matches twice on a single ending slash!
				return (s:gsub(add_patt, sep):gsub(repl_patt, sep))
			else
				return (s:gsub(add_patt, sep))
			end
		else --get separator
			return s:match(replace_only and repl_patt or add_patt)
		end
	elseif win then --detect separator for Windows paths
		local fws = s:find('/', 1, true)
		local bks = s:find('\\', 1, true)
		if not fws == not bks then
			return nil --can't determine
		end
		return fws and '/' or '\\'
	else --detect separator for UNIX paths
		return '/'
	end
end)

--get the common prefix (including the end separator) between two paths.
function path.common(p1, p2, pl)
	local win = win(pl)
	local type1, p1, drive1 = path.parse(p1, pl)
	local type2, p2, drive2 = path.parse(p2, pl)
	local p = #p1 <= #p2 and p1 or p2
	if win then --make the search case-insensitive and normalize separators
		drive1 = drive1 and drive1:lower()
		drive2 = drive2 and drive2:lower()
		p1 = p1:lower():gsub('/', '\\')
		p2 = p2:lower():gsub('/', '\\')
	end
	if type1 ~= type2 or drive1 ~= drive2 or p1 == '' or p2 == '' then
		return ''
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
	local p1 = p:sub(1, si)
	return path.format(type1, p1, drive1)
end

--get the last path component of a path.
--if the path ends in a separator then the empty string is returned.
path.basename = wrap(function(s, pl)
	return s:match(win(pl) and '[^\\/]*$' or '[^/]*$')
end)

--get the file extension or nil if there is none.
path.extname = wrap(function(s, pl)
	local patt = win(pl) and '%.([^%.\\/]+)$' or '%.([^%./]+)$'
	return path.basename(s, pl):match(patt)
end)

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
	local prefix = path.common(s, pwd, pl)
	--count the dir depth in pwd after the prefix.
	local pwd2 = pwd:sub(#prefix + 1)
	local n = 0
	for _ in pwd2:gmatch(win and '()[^\\/]+' or '()[^/]+') do
		n = n + 1
	end
	local s2 = s:sub(#prefix + 1)
	return ('../'):rep(n) .. s2
end)

print(path.rel('/a/b/f', '/a/c/d'))

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

path.join = table.concat

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

