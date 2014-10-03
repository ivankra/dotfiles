python <<ENDPYTHON
import vim, re, datetime, math

TX_RE = re.compile('^([0-9][0-9/=]+\s*(?:[*!]|))\s*(.*)$')
AC_PREF_RE = re.compile('^(\s+(?:[*!]\s*|))((?:[^\s]|[^\s]\s[^\s])*)$')
AC_RE = re.compile('^(\s+(?:[*!]\s*|))((?:[^\s]|[^\s]\s[^\s])+)(\s\s+(.*)|\s*)(|;.*)$')

def get_indent():
  row = int(vim.eval('v:lnum'))
  sw = int(vim.eval('shiftwidth()'))
  if row <= 1: return 0
  prev_line = vim.current.buffer[row - 2]
  if len(prev_line.strip()) == 0: return 0
  if prev_line[0].isdigit(): return sw
  return sw

  count = 0
  for char in reversed(line):
      if not re.match('[\w\d:]', char):
          break
      count += 1
  return column - count

def is_findstart():
  return vim.eval('a:findstart') == '1'

def filter_and_rank_completions(v):
  base = vim.eval('a:base')
  base_l = base.lower()
  freq = dict()
  for i, s in enumerate(v):
    freq[s] = freq.get(s, 0) + math.pow(1.01, i)
  def key(s):
    if s.startswith(base): return (1, -freq[s], s)
    pos = s.lower().find(base_l)
    if pos == 0: return (2, -freq[s], s)
    if pos != -1: return (3, -freq[s], s)
  v = sorted([ key(s) for s in set(v) ])
  v = [ kv[2] for kv in v if kv ]
  return v

def complete_date():
  if is_findstart(): return 0
  v = [ datetime.date.today().strftime('%Y/%m/%d') ]
  row = vim.current.window.cursor[0] - 1
  while row >= 1:
    line = vim.current.buffer[row - 1]
    m = re.match('^([0-9/]{10}).*', line)
    if m:
      v.append(m.group(1))
      break
    row -= 1
  v = filter_and_rank_completions(v)
  v.sort()
  return v

def complete_tx(m):
  if is_findstart(): return len(m.group(1))
  v = []
  for line_no, line in enumerate(vim.current.buffer):
    if line_no == vim.current.window.cursor[0] - 1: continue
    m = TX_RE.match(line)
    if m: v.append(m.group(2))
  return filter_and_rank_completions(v)

def complete_ac(m):
  if is_findstart(): return len(m.group(1))
  v = []
  for line_no, line in enumerate(vim.current.buffer):
    if line_no == vim.current.window.cursor[0] - 1: continue
    m = AC_RE.match(line)
    if m: v.append(m.group(2))
  return filter_and_rank_completions(v)

def get_completions():
  row, column = vim.current.window.cursor
  line = vim.current.line[:column]

  if re.match('^[0-9/]*$', line):
    return complete_date()

  m = TX_RE.match(line)
  if m:
    return complete_tx(m)

  m = AC_PREF_RE.match(line)
  if m:
    return complete_ac(m)

  if is_findstart(): return -1
  return []

ENDPYTHON

fun! MyCompleteFunc(findstart, base)
  return pyeval("get_completions()")
endfun

fun! MyIndentFunc()
  return pyeval("get_indent()")
endfun

set completefunc=MyCompleteFunc
set omnifunc=MyCompleteFunc
set indentexpr=MyIndentFunc()
set nocindent nosmartindent sw=4 et
inoremap <C-N> <C-X><C-O>
