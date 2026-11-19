import fcntl
import os
import pty
import struct
import sys
import termios


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


def resize() -> None:
    columns = os.environ.get("REVAMPED_TEST_TTY_COLS", "")
    if columns.isdigit():
        size = struct.pack("HHHH", 24, int(columns), 0, 0)
        fcntl.ioctl(0, termios.TIOCSWINSZ, size)


def main() -> int:
    typed = sys.stdin.buffer.read()
    pid, fd = pty.fork()
    if pid == 0:
        resize()
        os.execvp(sys.argv[1], sys.argv[1:])
    if typed:
        os.write(fd, typed)
    relay(fd)
    _, status = os.waitpid(pid, 0)
    return os.waitstatus_to_exitcode(status)


sys.exit(main())
