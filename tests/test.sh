#!/usr/bin/env bash
set -uo pipefail

mkdir -p /logs/verifier
export PATH="/usr/local/cargo/bin:/opt/task-venv/bin:${PATH}"
export RUSTUP_HOME="/usr/local/rustup"
export CARGO_HOME="/usr/local/cargo"

cd /target

git config --global safe.directory "*" >/dev/null 2>&1 || true

# Apply hidden behavioral tests
if [ -f /tests/test_patch.diff ]; then
    echo "==> applying hidden test patch"
    if ! git apply --whitespace=nowarn -p1 /tests/test_patch.diff; then
        echo "ERROR: failed to apply /tests/test_patch.diff" >&2
        echo 0 > /logs/verifier/reward.txt
        exit 1
    fi
fi

# Build the binary
BUILD_CMD=$(python3 -c "import json; print(json.load(open('/tests/config.json'))['build_cmd'])")
TEST_CMD=$(python3 -c "import json; print(json.load(open('/tests/config.json'))['test_cmd'])")

echo "==> build: $BUILD_CMD"
set +e
bash -c "$BUILD_CMD"
BUILD_EXIT=$?
set -e

if [ $BUILD_EXIT -ne 0 ]; then
    echo "ERROR: build failed with exit code $BUILD_EXIT" >&2
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run behavioral tests — output both to log file and visible stdout
PYTEST_LOG=/logs/verifier/pytest_output.txt
echo "==> test: $TEST_CMD"
set +e
bash -c "$TEST_CMD" 2>&1 | tee "$PYTEST_LOG"
TEST_EXIT=${PIPESTATUS[0]}
set -e

# Parse results using log_parsers.py
RESULTS_JSON=$(mktemp /tmp/sycamore-results.XXXXXX.json)
python3 /tests/log_parsers.py "$PYTEST_LOG" /dev/null "$RESULTS_JSON" /tests/config.json

if [ ! -f "$RESULTS_JSON" ]; then
    echo "ERROR: parser did not produce output" >&2
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

cp "$RESULTS_JSON" /logs/verifier/output.json

# Score against FAIL_TO_PASS
RESULTS_JSON=$(mktemp /tmp/sycamore-results.XXXXXX.json)
python3 /tests/log_parsers.py "$PYTEST_LOG" /dev/null "$RESULTS_JSON" /tests/config.json

if [ ! -f "$RESULTS_JSON" ]; then
    echo "ERROR: parser did not produce output" >&2
    echo 0 > /logs/verifier/reward.txt
    echo '{"reward": 0}' > /logs/verifier/reward.json
    exit 1
fi

cp "$RESULTS_JSON" /logs/verifier/output.json

python3 - "$RESULTS_JSON" <<'PY_SCORE'
import json
import sys

def _coerce(value):
    if isinstance(value, list):
        return value
    if isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return []
    return []

def _matches(target, candidates):
    if target in candidates:
        return True
    return any(
        candidate.endswith("/" + target) or target.endswith("/" + candidate)
        for candidate in candidates
    )

with open(sys.argv[1], "r", encoding="utf-8") as f:
    results = json.load(f)
with open("/tests/config.json", "r", encoding="utf-8") as f:
    config = json.load(f)

fail_to_pass = _coerce(config.get("FAIL_TO_PASS") or [])
pass_to_pass = _coerce(config.get("PASS_TO_PASS") or [])
passed = {item.get("name", "") for item in results.get("tests", []) if item.get("status") == "PASSED"}

missing_fail = [name for name in fail_to_pass if not _matches(name, passed)]
missing_pass = [name for name in pass_to_pass if not _matches(name, passed)]
success = not missing_fail and not missing_pass
score = 1.0 if success else 0.0

# Write minimal numeric reward.json for Harbor
with open("/logs/verifier/reward.json", "w", encoding="utf-8") as f:
    json.dump({
        "score": score,
        "resolved": success,
        "fail_to_pass": score,
        "pass_to_pass": 1.0 if not missing_pass else 0.0,
    }, f)

# Write detailed info separately for debugging
details = {
    "fail_to_pass_detail": {
        "total": len(fail_to_pass),
        "passed": len(fail_to_pass) - len(missing_fail),
        "missing": sorted(missing_fail),
    },
    "pass_to_pass_detail": {
        "total": len(pass_to_pass),
        "passed": len(pass_to_pass) - len(missing_pass),
        "missing": sorted(missing_pass),
    },
}
with open("/logs/verifier/reward-details.json", "w", encoding="utf-8") as f:
    json.dump(details, f, indent=2)

print("Required tests:", len(fail_to_pass) + len(pass_to_pass))
print("Passed required tests:", len(fail_to_pass) + len(pass_to_pass) - len(missing_fail) - len(missing_pass))
if missing_fail:
    print("Missing FAIL_TO_PASS:", sorted(missing_fail))

sys.exit(0 if success else 1)
PY_SCORE

SCORE_EXIT=$?
if [ $SCORE_EXIT -eq 0 ]; then
    echo 1 > /logs/verifier/reward.txt
else
    echo 0 > /logs/verifier/reward.txt
fi
exit $SCORE_EXIT
