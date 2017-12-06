local path = require'path'

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

--separator ------------------------------------------------------------------

local function test(s, s2, pl, which, sep)
	local s1 = path.separator(s, pl, which, sep)
	print('sep',
		s, pl, which, sep, '->', s1)
	assert(s1 == s2)
end

--empty paths
test('C:',     'C:',      'win', 'start',  '\\')
test('C:',     'C:',      'win', 'end',    '\\')
test('C:',     'C:',      'win', 'all',    '\\')

--duplicate separators / set
test('C:/\\/', 'C:/',     'win', 'start', '/')
test('C:/\\/', 'C:/',     'win', 'end',   '/')
test('C:/\\/', 'C:/',     'win', 'all',   '/')

--duplicate separators / remove
test('C:/\\/a/\\/', 'C:/a/\\/', 'win', 'start', '')
test('C:/\\/a/\\/', 'C:/\\/a/', 'win', 'end',   '')
test('C:/\\/a/\\/', 'C:/a/',    'win', 'all',   '')

--add/change separator
test('C:a/b',  'C:\\a/b', 'win', '+start', '\\')
test('C:/a/b', 'C:\\a/b', 'win', '+start', '\\')
test('C:a/b',  'C:a/b\\', 'win', '+end',   '\\')
test('C:a/b/', 'C:a/b\\', 'win', '+end',   '\\')

--replace sepaqrator
test('C:a/b',  'C:a/b',   'win', 'start', '\\')
test('C:/a/b', 'C:\\a/b', 'win', 'start', '\\')
test('C:a/b',  'C:a/b',   'win', 'end',   '\\')
test('C:a/b/', 'C:a/b\\', 'win', 'end',   '\\')

--remove separator
test('C:a/b/',  'C:a/b/', 'win', '+start', '')
test('C:/a/b/', 'C:a/b/', 'win', '+start', '')
test('C:a/b/',  'C:a/b/', 'win', 'start' , '')
test('C:/a/b/', 'C:a/b/', 'win', 'start' , '')
test('C:/a/b',  'C:/a/b', 'win', '+end'  , '')
test('C:/a/b/', 'C:/a/b', 'win', '+end'  , '')
test('C:/a/b',  'C:/a/b', 'win', 'end'   , '')
test('C:/a/b/', 'C:/a/b', 'win', 'end'   , '')

--replace with detected separator
test('C:a/b',    'C:/a/b',    'win', '+start', true) --detected
test('C:a\\b',   'C:\\a\\b',  'win', '+start', true) --detected
test('C:a',      'C:\\a',     'win', '+start', true) --default
test('C:a/b/c',  'C:a\\b\\c', 'win', 'all'   , true) --default (enforced)
test('C:a/b\\c', 'C:a\\b\\c', 'win', 'all'   , true) --default

--find separator
test('C:a/b', nil, 'win', 'start')
test('C:a/b', nil, 'win', 'end')
test('C:a/b', '',  'win', '+start')
test('C:a/b', '',  'win', '+end')
test('C:a/b' , '/' , 'win', 'all')
test('C:a\\b', '\\', 'win', 'all')
test('C:a/b' , '/' , 'win') --all
test('C:a\\b', '\\', 'win') --all
test('C:/a/b', '/', 'win', 'start')
test('C:/a/b', '/', 'win', '+start')
test('C:a/b/', '/', 'win', 'end')
test('C:a/b/', '/', 'win', '+end')

--remove duplicate separators only
test('C:a/\\\\//b\\\\//c', 'C:a/b\\c', 'win', 'all', '%1')

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

