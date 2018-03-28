import os, re
import pygments

from IPython.terminal import interactiveshell
from pygments.token import Token

def HasParentProcess(pattern):
  pid = os.getpid()
  for i in range(10):
    try:
      pid = int(open('/proc/%d/stat' % pid).read().split()[3])
      cmdline = open('/proc/%d/cmdline' % pid).read().replace('\0', ' ')
    except:
      break
    if re.match(pattern, cmdline):
      return True
  return False


if os.environ.get('GUAKE_TAB_UUID', '') != '' or HasParentProcess('.*guake.*'):
  c.InteractiveShell.colors = 'linux'
  c.TerminalInteractiveShell.highlighting_style_overrides = {
      Token.Prompt: '#ansigreen',
      Token.PromptNum: '#ansigreen bold',
      Token.OutPrompt: '#ansired',
      Token.OutPromptNum: '#ansired bold',
  }
else:
  c.InteractiveShell.colors = 'lightbg'
  c.InteractiveShell.highlighting_style = 'tango'
