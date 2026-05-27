from __future__ import annotations

import json
import re
import sys
from enum import Enum
from pathlib import Path


class TestStatus(str, Enum):
    PASSED = "PASSED"
    FAILED = "FAILED"
    SKIPPED = "SKIPPED"
    ERROR = "ERROR"


TestStatus.__test__ = False


ANSI_RE = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")
C0_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f]")


PYTEST_NAME_FIRST = re.compile(
    r"^(?P<name>\S+::\S+)\s+(?P<status>PASSED|FAILED|SKIPPED|ERROR|XPASS|XFAIL)\b"
)
PYTEST_STATUS_FIRST = re.compile(
    r"^(?P<status>PASSED|FAILED|SKIPPED|ERROR|XPASS|XFAIL)\s+(?P<name>\S+::\S+)"
)
PYTEST_XDIST = re.compile(
    r"\[gw\d+\][^\n]*?(?P<status>PASSED|FAILED|SKIPPED|ERROR|XPASS|XFAIL)\s+(?P<name>\S+::\S+)"
)

PYTEST_STATUS_NORMALIZE = {
    "PASSED": TestStatus.PASSED.value,
    "FAILED": TestStatus.FAILED.value,
    "SKIPPED": TestStatus.SKIPPED.value,
    "ERROR": TestStatus.ERROR.value,
    "XPASS": TestStatus.PASSED.value,
    "XFAIL": TestStatus.SKIPPED.value,
}


def strip_noise(text: str) -> str:
    if not text:
        return text
    return C0_RE.sub("", ANSI_RE.sub("", text))


def parse_log_pytest(log: str) -> dict[str, str]:
    log = strip_noise(log)
    tests: dict[str, str] = {}

    for line in log.splitlines():
        stripped = line.strip()
        if not stripped:
            continue

        match = PYTEST_XDIST.search(stripped)
        if not match:
            match = PYTEST_NAME_FIRST.match(stripped)
        if not match:
            match = PYTEST_STATUS_FIRST.match(stripped)
        if not match:
            continue

        tests[match.group("name")] = PYTEST_STATUS_NORMALIZE[match.group("status")]

    return tests


def get_parser(name: str | None):
    if not name or name == "parse_log_pytest":
        return parse_log_pytest
    raise SystemExit(f"unsupported log parser: {name}")


def main() -> int:
    if len(sys.argv) < 4:
        raise SystemExit("usage: log_parsers.py STDOUT STDERR OUTPUT [CONFIG]")

    stdout_path, stderr_path, output_path = map(Path, sys.argv[1:4])
    config_path = Path(sys.argv[4]) if len(sys.argv) > 4 else None

    parser_name = "parse_log_pytest"
    if config_path and config_path.is_file():
        config = json.loads(config_path.read_text(encoding="utf-8"))
        parser_name = config.get("log_parser") or parser_name

    combined = ""
    for path in (stdout_path, stderr_path):
        if path.is_file():
            combined += path.read_text(errors="replace") + "\n"

    parser = get_parser(parser_name)
    parsed = parser(combined)
    tests = [{"name": name, "status": status} for name, status in parsed.items()]
    output_path.write_text(json.dumps({"tests": tests}, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
