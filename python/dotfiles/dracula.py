# -*- coding: utf-8 -*-
# Based on https://github.com/dracula/pygments/blob/master/dracula.py
# With some modifications for better constrast and hacks for setting
# up in xonsh and ipython.

"""
    Dracula Theme v1.2.5
    https://github.com/zenorocha/dracula-theme
    Copyright 2016, All rights reserved
    Code licensed under the MIT license
    http://zenorocha.mit-license.org
    :author Rob G <wowmotty@gmail.com>
    :author Chris Bracco <chris@cbracco.me>
    :author Zeno Rocha <hi@zenorocha.com>
"""

from pygments.style import Style
from pygments.token import Keyword, Name, Comment, String, Error, \
    Literal, Number, Operator, Other, Punctuation, Text, Generic, \
    Whitespace, Token


class DraculaStyle(Style):
    background_color = "#282a36"
    default_style = ""

    styles = {
        Comment: "#7a8fcc",
        Comment.Hashbang: "#7a8fcc",
        Comment.Multiline: "#7a8fcc",
        Comment.Preproc: "#ff79c6",
        Comment.Single: "#7a8fcc",
        Comment.Special: "#7a8fcc",
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


def xonsh_dracula_style():
    from xonsh.pyghooks import _expand_style
    Color = Token.Color
    # Based on xonsh.pyghooks._monokai_style
    style = {
        Color.BLACK: "#1e0010",
        Color.BLUE: "#6666ef",
        Color.CYAN: "#66d9ef",
        Color.GREEN: "#2ee22e",
        Color.INTENSE_BLACK: "#5e5e5e",
        Color.INTENSE_BLUE: "#2626d7",
        Color.INTENSE_CYAN: "#2ed9d9",
        Color.INTENSE_GREEN: "#a6e22e",
        Color.INTENSE_PURPLE: "#ae81ff",
        Color.INTENSE_RED: "#f92672",
        Color.INTENSE_WHITE: "#f8f8f2",
        Color.INTENSE_YELLOW: "#e6db74",
        Color.NO_COLOR: "noinherit",
        Color.PURPLE: "#960050",
        Color.RED: "#AF0000",
        Color.WHITE: "#d7d7d7",
        Color.YELLOW: "#e2e22e",
    }
    _expand_style(style)
    return style


def gsbn(fn):
    return lambda name: DraculaStyle if name == 'dracula' else fn(name)


def set_xonsh():
    import xonsh.pyghooks
    xonsh.pyghooks.STYLES['dracula'] = xonsh_dracula_style()
    xonsh.pyghooks.get_style_by_name = gsbn(xonsh.pyghooks.get_style_by_name)


def set_ipython(c):
    import IPython
    c.TerminalInteractiveShell.colors = 'linux'
    if IPython.version_info >= (5, 2, 0, ''):
        c.TerminalInteractiveShell.highlighting_style = DraculaStyle
    else:
        from IPython.terminal import interactiveshell
        interactiveshell.get_style_by_name = gsbn(interactiveshell.get_style_by_name)
        c.TerminalInteractiveShell.highlighting_style = 'dracula'

    c.TerminalInteractiveShell.highlighting_style_overrides = {
        Token.Prompt: '#33cc33',
        Token.PromptNum: '#66ff66 bold',
        Token.OutPrompt: '#ff0000',
        Token.OutPromptNum: '#ff0000 bold',
    }
