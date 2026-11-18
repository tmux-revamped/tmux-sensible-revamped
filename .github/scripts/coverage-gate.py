import json
import re
import sys
from pathlib import Path

ARTIFACT = re.compile(r"\A\s*(done\s*[<>].*|[^()\s]+\)\s*;;|\)(\s+\S*>\S*)*\s*&?|.*\|\s*\\)\s*\Z")
HEREDOC = re.compile(r"<<-?\s*'?([A-Za-z_][A-Za-z0-9_]*)'?\s*$")
Counts = list[int | None]
Line = tuple[str, int, int, str]


def relative_key(file: str, pattern: re.Pattern[str]) -> str | None:
    match = pattern.search(file)
    return file[match.start() + 1 :] if match else None


def add_counts(merged: dict[str, Counts], key: str, counts: Counts) -> None:
    lines = merged.setdefault(key, [None] * len(counts))
    for index, count in enumerate(counts):
        if count is not None:
            lines[index] = (lines[index] or 0) + count


def merged_lines(paths: list[str], pattern: re.Pattern[str]) -> dict[str, Counts]:
    merged: dict[str, Counts] = {}
    for path in paths:
        runs = json.loads(Path(path).read_text(encoding="utf-8"))
        for run in runs.values():
            for file, data in run["coverage"].items():
                key = relative_key(file, pattern)
                if key is not None:
                    add_counts(merged, key, data["lines"] if isinstance(data, dict) else data)
    return merged


def heredoc_lines(source: list[str]) -> set[int]:
    data: set[int] = set()
    terminator = None
    for index, line in enumerate(source):
        if terminator is not None:
            data.add(index)
            if line.strip() == terminator:
                terminator = None
            continue
        match = HEREDOC.search(line)
        if match:
            terminator = match.group(1)
    return data


def relevant_lines(key: str, counts: Counts) -> list[Line]:
    source = Path(key).read_text(encoding="utf-8").splitlines()
    data = heredoc_lines(source)
    return [
        (key, index + 1, count, source[index].strip())
        for index, count in enumerate(counts)
        if count is not None and index not in data and not ARTIFACT.match(source[index])
    ]


def main(pattern: str, minimum: float, paths: list[str]) -> int:
    merged = merged_lines(paths, re.compile(pattern))
    if not merged:
        sys.stderr.write(f"no covered files match {pattern}\n")
        return 1
    lines = [line for key, counts in merged.items() for line in relevant_lines(key, counts)]
    misses = [line for line in lines if line[2] == 0]
    for key, number, _count, text in misses:
        sys.stdout.write(f"{key}:{number}: {text}\n")
    covered = len(lines) - len(misses)
    percent = 100.0 * covered / len(lines) if lines else 100.0
    summary = f"covered {covered} of {len(lines)} lines ({percent:.2f}%), gate {minimum:.2f}%"
    sys.stdout.write(f"{summary}\n")
    return 1 if percent + 1e-9 < minimum else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], float(sys.argv[2]), sys.argv[3:]))
