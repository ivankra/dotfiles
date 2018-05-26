import os
import re
import IPython

from pygments.style import Style
from pygments.token import Comment, Error, Generic, Keyword, Literal, Name, \
    Number, Operator, Other, Punctuation, String, Text, Token, Whitespace


def HasParentProcess(cmdline_pattern):
  pid = os.getpid()
  for i in range(10):
    try:
      pid = int(open('/proc/%d/stat' % pid).read().split()[3])
      cmdline = open('/proc/%d/cmdline' % pid).read().replace('\0', ' ')
    except:
      break
    if re.match(cmdline_pattern, cmdline):
      return True
  return False


# Based on https://github.com/dracula/pygments/blob/master/dracula.py
class DraculaStyle(Style):
    background_color = "#282a36"
    default_style = ""

    styles = {
        Comment: "#6272a4",
        Comment.Hashbang: "#6272a4",
        Comment.Multiline: "#6272a4",
        Comment.Preproc: "#ff79c6",
        Comment.Single: "#6272a4",
        Comment.Special: "#6272a4",
        Generic: "#ffffff",
        Generic.Deleted: "#8b080b",
        Generic.Emph: "#ffffff underline",
        Generic.Error: "#ffffff",
        Generic.Heading: "#ffffff bold",
        Generic.Inserted: "#ffffff bold",
        Generic.Output: "#44475a",
        Generic.Prompt: "#ffffff",
        Generic.Strong: "#ffffff",
        Generic.Subheading: "#ffffff bold",
        Generic.Traceback: "#ffffff",
        Error: "#ffffff",
        Keyword: "#ff79c6 bold",
        Keyword.Constant: "#ff79c6 bold",
        Keyword.Declaration: "#8be9fd bold italic",
        Keyword.Namespace: "#ff79c6 bold",
        Keyword.Pseudo: "#ff79c6 bold",
        Keyword.Reserved: "#ff79c6 bold",
        Keyword.Type: "#8be9fd bold",
        Literal: "#ffffff",
        Literal.Date: "#ffffff",
        Name: "#ffffff",
        Name.Attribute: "#50fa7b bold",
        Name.Builtin: "#8be9fd bold",
        Name.Builtin.Pseudo: "#ffffff",
        Name.Class: "#50fa7b bold",
        Name.Constant: "#ffffff",
        Name.Decorator: "#ffffff",
        Name.Entity: "#ffffff",
        Name.Exception: "#ffffff",
        Name.Function: "#50fa7b bold",
        Name.Label: "#8be9fd italic",
        Name.Namespace: "#ffffff",
        Name.Other: "#ffffff",
        Name.Tag: "#ff79c6",
        Name.Variable: "#8be9fd italic",
        Name.Variable.Class: "#8be9fd italic",
        Name.Variable.Global: "#8be9fd italic",
        Name.Variable.Instance: "#8be9fd italic",
        Number: "#99ffff bold",
        Number.Bin: "#99ffff bold",
        Number.Float: "#99ffff bold",
        Number.Hex: "#99ffff bold",
        Number.Integer: "#99ffff bold",
        Number.Integer.Long: "#99ffff bold",
        Number.Oct: "#99ffff bold",
        Operator: "#ff79c6 bold",
        Operator.Word: "#ff79c6 bold",
        Other: "#ffffff",
        Punctuation: "#ffffff",
        String: "#ffff99 bold",
        String.Backtick: "#ffff99",
        String.Char: "#ffff99",
        String.Doc: "#ffff99",
        String.Double: "#ffff99",
        String.Escape: "#ffff99",
        String.Heredoc: "#ffff99",
        String.Interpol: "#ffff99",
        String.Other: "#ffff99",
        String.Regex: "#ffff99",
        String.Single: "#ffff99",
        String.Symbol: "#ffff99",
        Text: "#ffffff",
        Whitespace: "#ffffff"
}


# Use a good legible dark theme if running under Guake
if (os.environ.get('COLORFGBG', '').endswith(';0') or
    os.environ.get('GUAKE_TAB_UUID', '') != '' or
    HasParentProcess('.*guake.*')):
  c.TerminalInteractiveShell.colors = 'linux'
  if IPython.version_info >= (5, 2, 0, ''):
    c.TerminalInteractiveShell.highlighting_style = DraculaStyle
  else:
    from IPython.terminal import interactiveshell
    def _get_style_by_name(name, orig=interactiveshell.get_style_by_name):
      return DraculaStyle if name == 'dracula' else orig(name)
    interactiveshell.get_style_by_name = _get_style_by_name
    c.TerminalInteractiveShell.highlighting_style = 'dracula'

  c.TerminalInteractiveShell.highlighting_style_overrides = {
      Token.Prompt: '#33cc33',
      Token.PromptNum: '#66ff66 bold',
      Token.OutPrompt: '#ff0000',
      Token.OutPromptNum: '#ff0000 bold',
  }
else:
  c.TerminalInteractiveShell.colors = 'lightbg'
  c.TerminalInteractiveShell.highlighting_style = 'tango'

c.TerminalInteractiveShell.confirm_exit = False
c.TerminalInteractiveShell.banner1 = ''
c.TerminalInteractiveShell.banner2 = ''
c.TerminalIPythonApp.display_banner = False
