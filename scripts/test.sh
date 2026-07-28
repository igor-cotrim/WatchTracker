#!/bin/bash
# Runs the WatchTracker unit test suite on a simulator.
#
# Usage:
#   ./scripts/test.sh                      # all tests
#   ./scripts/test.sh WatchTrackerTests/EndpointTests   # a single suite
#
# Override the simulator with DEVICE, e.g. DEVICE="iPhone 15" ./scripts/test.sh
set -euo pipefail

cd "$(dirname "$0")/.."

DEVICE="${DEVICE:-iPhone 16 Pro}"
RESULT_BUNDLE="${RESULT_BUNDLE:-build/TestResults.xcresult}"

# Resolve the device by udid: several installed runtimes can share a device name,
# which makes `name=` destinations ambiguous and fail to match.
UDID=$(xcrun simctl list devices available \
  | grep -E "^ +${DEVICE} \(" \
  | head -1 \
  | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')

if [ -z "$UDID" ]; then
  echo "No available simulator named '$DEVICE'. Available:" >&2
  xcrun simctl list devices available | grep -E "^ +iPhone" >&2
  exit 1
fi

rm -rf "$RESULT_BUNDLE"
mkdir -p "$(dirname "$RESULT_BUNDLE")"

ARGS=(
  test
  -project WatchTracker.xcodeproj
  -scheme WatchTracker
  -destination "platform=iOS Simulator,id=$UDID"
  -enableCodeCoverage YES
  -resultBundlePath "$RESULT_BUNDLE"
)

for suite in "$@"; do
  ARGS+=(-only-testing:"$suite")
done

set -o pipefail
if xcodebuild "${ARGS[@]}" 2>&1 | tee build/test.log | grep -E "error:|' failed|Test Suite|TEST (SUCCEEDED|FAILED)"; then
  :
fi

if grep -q "\*\* TEST SUCCEEDED \*\*" build/test.log; then
  echo
  echo "Coverage:"
  xcrun xccov view --report --only-targets "$RESULT_BUNDLE"
  exit 0
else
  echo
  echo "Failures:"
  grep -E "error:|' failed" build/test.log | sort -u || true
  exit 1
fi
