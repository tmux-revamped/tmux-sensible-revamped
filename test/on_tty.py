import os
import pty
import sys


def relay(fd: int) -> None:
    while True:
        try:
            data = os.read(fd, 4096)
        except OSError:
            return
        if not data:
            return
        sys.stdout.buffer.write(data)
        sys.stdout.buffer.flush()


def main() -> int:
    typed = sys.stdin.buffer.read()
    pid, fd = pty.fork()
    if pid == 0:
        os.execvp(sys.argv[1], sys.argv[1:])
    if typed:
        os.write(fd, typed)
    relay(fd)
    _, status = os.waitpid(pid, 0)
    return os.waitstatus_to_exitcode(status)


sys.exit(main())
