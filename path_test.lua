local path = require'path'

assert(path.platform == 'win' or path.platform == 'unix')
assert(path.sep'win' == '\\')
assert(path.sep'unix' == '/')
assert(path.sep() == path.sep(path.platform))

assert(path.dev_alias'NUL' == 'NUL')
assert(path.dev_alias'c:/a/b/con.txt' == 'CON')

--type -----------------------------------------------------------------------

assert(path.type('c:\\', 'win') == 'abs')
assert(path.type('c:/a/b', 'win') == 'abs')
assert(path.type('/', 'unix') == 'abs')
assert(path.type('/a/b', 'unix') == 'abs')
assert(path.type('\\\\?\\C:\\', 'win') == 'abs_long')
assert(path.type('/a/b', 'win') == 'abs_nodrive')
assert(path.type('', 'win') == 'rel')
assert(path.type('a', 'win') == 'rel')
assert(path.type('a/b', 'win') == 'rel')
assert(path.type('C:', 'win') == 'rel_drive')
assert(path.type('C:a', 'win') == 'rel_drive')
assert(path.type('\\\\', 'win') == 'unc')
assert(path.type('\\\\server\\share', 'win') == 'unc')
assert(path.type('\\\\?\\UNC\\', 'win') == 'unc_long')
assert(path.type('\\\\?\\UNC\\server', 'win') == 'unc_long')
assert(path.type('\\\\?\\UNC\\server\\share', 'win') == 'unc_long')
assert(path.type('\\\\?\\', 'win') == 'global')
assert(path.type('\\\\?\\a', 'win') == 'global')
assert(path.type('\\\\.\\', 'win') == 'dev')
assert(path.type('\\\\.\\a', 'win') == 'dev')
assert(path.type('c:/nul', 'win') == 'dev_alias')

--isabs ----------------------------------------------------------------------

local function test(s, pl, isabs2, isempty2)
	local isabs1, isempty1 = path.isabs(s, pl)
	print('isabs', s, pl, '->', isabs1, isempty1)
	assert(isabs1 == isabs2)
	assert(isempty1 == isempty2)
end

test('',     'win', false, true)
test('/',    'win', true,  true)
test('\\//', 'win', true,  true)
test('C:',   'win', false, true)
test('C:/',  'win', true,  true)
test('C:/a', 'win', true,  false)
test('a',    'win', false, false)
test('C:/path/con.txt', 'win', false, false) --device alias but appears abs

test('\\\\', 'win', true, nil) --invalid
test('\\\\server', 'win', true, nil) --invalid
test('\\\\server\\', 'win', true, true) --still invalid but better :)
test('\\\\server\\share', 'win', true, false) --valid

test('/', 'unix', true, true)
test('', 'unix', false, true)

--endsep ---------------------------------------------------------------------

--TODO: `path.endsep(s, [pl], [sep]) -> s, success`

--separator ------------------------------------------------------------------

local function test(s, s2, pl, sep, default_sep, empty_names)
	local s1 = path.separator(s, pl, sep, default_sep, empty_names)
	print('sep', s, pl, which, sep, default_sep, empty_names, '->', s1)
	assert(s1 == s2)
end

--TODO

--basename -------------------------------------------------------------------

local function test(s, pl, s2)
	local s1 = path.basename(s, pl)
	print('basenam', s, pl, '->', s1)
	assert(s1 == s2)
end
test(''    , 'win', '')
test('/'   , 'win', '')
test('a'   , 'win', 'a')
test('a/'  , 'win', '')
test('/a'  , 'win', 'a')
test('a/b' , 'win', 'b')
test('a/b/', 'win', '')

--splitext -------------------------------------------------------------------

local function test(s, pl, name2, ext2)
	local name1, ext1 = path.splitext(s, pl)
	print('ext', s, pl, '->', name1, ext1)
	assert(name1 == name2)
	assert(ext1 == ext2)
end

test('',             'win', '', nil)
test('/',            'win', '', nil)
test('a/',           'win', '', nil)
test('/a/b/a',       'win', 'a', nil)
test('/a/b/a.',      'win', 'a', '') --invalid filename on Windows
test('/a/b/a.txt',   'win', 'a', 'txt')
test('/a/b/.bashrc', 'win', '.bashrc', nil)

--dirname --------------------------------------------------------------------

local function test(s, pl, s2)
	local s1 = path.dirname(s, pl)
	print('dirname', s, pl, '->', s1)
	assert(s1 == s2)
end

--TODO

--gsplit ---------------------------------------------------------------------

--TODO `path.gsplit(s, [pl], [full]) ->iter() ->s,sep`

--normalize ------------------------------------------------------------------

--TODO `path.normalize(s, [pl], [opt]) -> s`

local function test(s, pl, opt, r2)
	local r1 = path.normalize(s, pl, opt)
	print('normal', s, pl, require'pp'.format(opt), '->', r1)
	assert(r1 == r2)
end

--commonpath -----------------------------------------------------------------

local function test(a, b, pl, c2)
	local c1 = path.commonpath(a, b, pl)
	print('commpre', a, b, pl, '->', c1)
	assert(c1 == c2)
end

test('',         '',           'win', '')
test('/',        '/',          'win', '/')
test('C:',       'C:',         'win', 'C:')
test('c:/',      'C:/',        'win', 'c:/') --first when equal
test('C:/',      'C:\\',       'win', 'C:/') --first when equal
test('C:////////', 'c://',     'win', 'c://') --smallest
test('c://',     'C:////////', 'win', 'c://') --smallest
test('C:/',      'C:',         'win', 'C:')
test('C:',       'C:/',        'win', 'C:')
test('C:a',      'C:/',        'win', 'C:')
test('C:/a',     'C:/b',       'win', 'C:/')
test('C:a',      'C:b',        'win', 'C:')
test('C:/a/b',   'C:/a/c',     'win', 'C:/a/')
test('C:/a/b',   'C:/a/b/',    'win', 'C:/a/b')
test('C:/a/b/',  'C:/a/b/c',   'win', 'C:/a/b/')
test('C:/a/b',   'C:/a/bc',    'win', 'C:/a/')
test('C:/a//',   'C:/a//',     'win', 'C:/a//')
test('C:/a/c/d', 'C:/a/b/f',   'win', 'C:/a/')

--case-sensitivity
test('a/B',     'a/b',       'unix', 'a/')
test('C:a/B',   'C:a/b',     'win',  'C:a/B') --pick first
test('C:a/B/c', 'C:a/b/c/d', 'win',  'C:a/B/c') --pick smallest

--rel ------------------------------------------------------------------------

local function test(s, pwd, pl, r2)
	local r1 = path.rel(s, pwd, pl)
	print('rel', s, pwd, pl, '->', r1)
	assert(r1 == r2)
end

--combine (& implicitly abs) -------------------------------------------------

local function test(s, pwd, pl, r2)
	local r1 = path.abs(s, pwd, pl)
	print('abs', s, pwd, pl, '->', r1)
	assert(r1 == r2)
end

--filename -------------------------------------------------------------------

--TODO `path.filename(s, [pl], [repl]) -> s`




