import os
import re

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


class DarkStyle(Style):
    background_color = '#000000'
    default_style = '#ffffff'

    styles = {
        Token:              '#ffffff',
        Whitespace:         '#666666',
        Comment:            '#66cccc',
        Keyword:            'bold #33ff33',
        Keyword.Pseudo:     'nobold',
        Operator.Word:      'bold #33ff33',
        String:             '#99ccff bold',
        Number:             'bold #33ffff',
        Name.Builtin:       '#00bbff bold',
        Name.Function:      '#ffffff bold',
        Error:              '#ff6600',
        Generic.Heading:    '#ffffff bold',
        Generic.Output:     '#444444 bg:#222222',
        Generic.Subheading: '#ffffff bold',
    }


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
        Keyword: "#ff79c6",
        Keyword.Constant: "#ff79c6",
        Keyword.Declaration: "#8be9fd italic",
        Keyword.Namespace: "#ff79c6",
        Keyword.Pseudo: "#ff79c6",
        Keyword.Reserved: "#ff79c6",
        Keyword.Type: "#8be9fd",
        Literal: "#ffffff",
        Literal.Date: "#ffffff",
        Name: "#ffffff",
        Name.Attribute: "#50fa7b",
        Name.Builtin: "#8be9fd italic",
        Name.Builtin.Pseudo: "#ffffff",
        Name.Class: "#50fa7b",
        Name.Constant: "#ffffff",
        Name.Decorator: "#ffffff",
        Name.Entity: "#ffffff",
        Name.Exception: "#ffffff",
        Name.Function: "#50fa7b",
        Name.Label: "#8be9fd italic",
        Name.Namespace: "#ffffff",
        Name.Other: "#ffffff",
        Name.Tag: "#ff79c6",
        Name.Variable: "#8be9fd italic",
        Name.Variable.Class: "#8be9fd italic",
        Name.Variable.Global: "#8be9fd italic",
        Name.Variable.Instance: "#8be9fd italic",
        Number: "#bd93f9",
        Number.Bin: "#bd93f9",
        Number.Float: "#bd93f9",
        Number.Hex: "#bd93f9",
        Number.Integer: "#bd93f9",
        Number.Integer.Long: "#bd93f9",
        Number.Oct: "#bd93f9",
        Operator: "#ff79c6",
        Operator.Word: "#ff79c6",
        Other: "#ffffff",
        Punctuation: "#ffffff",
        String: "#f1fa8c",
        String.Backtick: "#f1fa8c",
        String.Char: "#f1fa8c",
        String.Doc: "#f1fa8c",
        String.Double: "#f1fa8c",
        String.Escape: "#f1fa8c",
        String.Heredoc: "#f1fa8c",
        String.Interpol: "#f1fa8c",
        String.Other: "#f1fa8c",
        String.Regex: "#f1fa8c",
        String.Single: "#f1fa8c",
        String.Symbol: "#f1fa8c",
        Text: "#ffffff",
        Whitespace: "#ffffff"
}


# Use a good legible dark theme if running under Guake
if os.environ.get('GUAKE_TAB_UUID', '') != '' or HasParentProcess('.*guake.*'):
  c.TerminalInteractiveShell.colors = 'linux'
  c.TerminalInteractiveShell.highlighting_style = DraculaStyle  #DarkStyle
  c.TerminalInteractiveShell.highlighting_style_overrides = {
      Token.Prompt: '#ansigreen',
      Token.PromptNum: '#ansigreen bold',
      Token.OutPrompt: '#ansired',
      Token.OutPromptNum: '#ansired bold',
  }
else:
  c.TerminalInteractiveShell.colors = 'lightbg'
  c.TerminalInteractiveShell.highlighting_style = 'tango'

c.TerminalInteractiveShell.confirm_exit = False
c.TerminalInteractiveShell.banner1 = ''
c.TerminalInteractiveShell.banner2 = ''
c.TerminalIPythonApp.display_banner = False
