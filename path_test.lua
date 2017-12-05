local path = require'path'

--separator ------------------------------------------------------------------

local function test(s, s2, pl, which, sep, repl_only)
	local s1 = path.separator(s, pl, which, sep, repl_only)
	print('sep',
		s, pl, which, sep, repl_only and 'repl' or 'set', '->', s1)
	assert(s1 == s2)
end

--empty paths
test('',     '\\',    'win', '+start', '\\')
test('',     '\\',    'win', '+end',   '\\')
test('',     '',      'win', 'start',  '\\')
test('',     '',      'win', 'end',    '\\')
test('',     '',      'win', 'all',    '\\')

--duplicate separators / set
test('/\\/', '/',     'win', 'start', '/')
test('/\\/', '/',     'win', 'end',   '/')
test('/\\/', '/',     'win', 'all',   '/')

--duplicate separators / remove
test('/\\/', '',     'win', 'start', '')
test('/\\/', '',     'win', 'end',   '')
test('/\\/', '',     'win', 'all',   '')

--add/change separator
test('a/b',  '\\a/b', 'win', '+start', '\\')
test('/a/b', '\\a/b', 'win', '+start', '\\')
test('a/b',  'a/b\\', 'win', '+end',   '\\')
test('a/b/', 'a/b\\', 'win', '+end',   '\\')

--replace sepaqrator
test('a/b',  'a/b',   'win', 'start', '\\')
test('/a/b', '\\a/b', 'win', 'start', '\\')
test('a/b',  'a/b',   'win', 'end',   '\\')
test('a/b/', 'a/b\\', 'win', 'end',   '\\')

--remove separator
test('a/b/',  'a/b/', 'win', '+start', '')
test('/a/b/', 'a/b/', 'win', '+start', '')
test('a/b/',  'a/b/', 'win', 'start' , '')
test('/a/b/', 'a/b/', 'win', 'start' , '')
test('/a/b',  '/a/b', 'win', '+end'  , '')
test('/a/b/', '/a/b', 'win', '+end'  , '')
test('/a/b',  '/a/b', 'win', 'end'   , '')
test('/a/b/', '/a/b', 'win', 'end'   , '')

--replace with detected separator
test('a/b',    '/a/b',    'win', '+start', true) --detected
test('a\\b',   '\\a\\b',  'win', '+start', true) --detected
test('a',      '\\a',     'win', '+start', true) --default
test('a/b/c',  'a\\b\\c', 'win', 'all'   , true) --default (enforced)
test('a/b\\c', 'a\\b\\c', 'win', 'all'   , true) --default

--find separator
test('a/b', nil, 'win', 'start')
test('a/b', nil, 'win', 'end')
test('a/b', '',  'win', '+start')
test('a/b', '',  'win', '+end')
test('a/b' , '/' , 'win', 'all')
test('a\\b', '\\', 'win', 'all')
test('a/b' , '/' , 'win') --all
test('a\\b', '\\', 'win') --all
test('/a/b', '/', 'win', 'start')
test('/a/b', '/', 'win', '+start')
test('a/b/', '/', 'win', 'end')
test('a/b/', '/', 'win', '+end')

--remove duplicate separators only
test('a/\\\\//b\\\\//c', 'a/b\\c', 'win', 'all', '%1')

--common ---------------------------------------------------------------------

local function test(a, b, pl, c2)
	local c1 = path.common(a, b, pl)
	print('common', a, b, '->', c1)
	assert(c1 == c2)
end
test('', '', 'win', '')
test('/', '/', 'win', '/')
test('/', '\\', 'win', '/') --first when equal
test('////////', '//', 'win', '//')
test('//', '////////', 'win', '//')
test('/', '', 'win', '')
test('', '/', 'win', '')
test('a', '/', 'win', '')
test('/a', '/b', 'win', '/')
test('a', 'b', 'win', '')
test('/a/b', '/a/c', 'win', '/a/')
test('/a/b', '/a/b/', 'win', '/a/b')
test('/a/b/', '/a/b/c', 'win', '/a/b/')
test('/a/b', '/a/bc', 'win', '/a/')
test('/a//', '/a//', 'win', '/a//')
test('/a/c/d', '/a/b/f', 'win', '/a/')

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

--dirname --------------------------------------------------------------------

local function test(s, pl, s2)
	local s1 = path.dirname(s, pl)
	print('dirname', s, pl, '->', s1)
	assert(s1 == s2)
end

--abs ------------------------------------------------------------------------

local function test(s, pwd, pl, r2)
	local r1 = path.abs(s, pwd, pl)
	print('abs', s, pwd, pl, '->', r1)
	assert(r1 == r2)
end


--rel ------------------------------------------------------------------------

local function test(s, pwd, pl, r2)
	local r1 = path.rel(s, pwd, pl)
	print('rel', s, pwd, pl, '->', r1)
	assert(r1 == r2)
end

--normalize ------------------------------------------------------------------

local function test(s, pl, opt, r2)
	local r1 = path.normalize(s, pl, opt)
	print('normal', s, pl, require'pp'.format(opt), '->', r1)
	assert(r1 == r2)
end

