import functools
import os
import sys
import xonsh.main


@functools.lru_cache(1000000)
def goo_access(path, attr):
    return os.access(path, attr)


def goofus(f):
    res = f.is_symlink() and os.readlink(f).startswith('/goo')
    res |= str(f.path).startswith('/usr')
    return res


def goo_yield(path):
    if not os.path.exists(path):
        return
    for file_ in os.scandir(path):
        try:
            if goofus(file_):
                if goo_access(file_.path, os.X_OK):
                    yield file_.name
            elif file_.is_file() and os.access(file_.path, os.X_OK):
                yield file_.name
        except OSError:
            pass


if sys.version_info[:2] >= (3, 6) and hasattr(xonsh.main, '_yield_accessible_unix_file_names'):
    xonsh.main._yield_accessible_unix_file_names = goo_yield
