"""Parse a Python file without running it.

Usage: python3 syntax_check.py python <file>

Exit 0 when the file parses. Otherwise print one line naming the error and
exit 1. simplify-check.sh runs it as the syntax gate for that kind; a file
on disk keeps the gate out of `python3 -c`, which the auto-mode classifier
refuses.
"""

import sys


def main(argv):
    if len(argv) != 3 or argv[1] != "python":
        print("usage: syntax_check.py python <file>", file=sys.stderr)
        return 2
    path = argv[2]
    try:
        with open(path, "rb") as handle:
            source = handle.read()
        compile(source, path, "exec")
    except OSError as error:
        print(f"cannot read {path}: {error.strerror}", file=sys.stderr)
        return 2
    except (SyntaxError, ValueError) as error:
        print(f"{type(error).__name__}: {error}".splitlines()[0])
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
