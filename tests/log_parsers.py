import re


def parse_log_pytest(log: str) -> dict:
    """
    Parse pytest output and return pass/fail counts and test results.
    """
    results = {}

    # Match individual test results e.g. "PASSED test_behavioral.py::TestClass::test_name"
    pattern = re.compile(
        r"(PASSED|FAILED|ERROR)\s+(test_\w+\.py::[\w:]+)"
    )

    for match in pattern.finditer(log):
        status, node_id = match.group(1), match.group(2)
        results[node_id] = status == "PASSED"

    # Summary counts
    passed = sum(1 for v in results.values() if v)
    failed = sum(1 for v in results.values() if not v)

    return {
        "passed": passed,
        "failed": failed,
        "results": results,
    }


if __name__ == "__main__":
    import sys
    log = sys.stdin.read()
    import json
    print(json.dumps(parse_log_pytest(log), indent=2))
