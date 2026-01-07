# Third-party code

Vendored code is directly checked in, possibly with local cleanups/edits -- see commit log.

Less critical and unmodified dependencies are in `../modules/<name>` submodules with with symlinks pointing there. Note: this extra indirection with symlinks is critical for dotfiles.deb which replaces them with symlinks to its own shared checkout of submodules.  Git doesn't like submodules directories directly being replaced with symlinks.
