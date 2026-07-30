#!/bin/bash
# Runs a WatchTracker test plan on a pinned simulator.
#
# Usage:
#   ./scripts/test.sh                                   # the Unit plan on the iOS floor
#   ./scripts/test.sh WatchTrackerTests/EndpointTests    # a single suite
#   PLAN=AI IOS_VERSION=26.2 ./scripts/test.sh            # the AI plan on iOS 26
#   MIN_COVERAGE=30 ./scripts/test.sh                     # fail below a coverage floor
#
# The device/runtime pair is pinned on purpose. Snapshot baselines and rendered
# layouts are specific to a simulator + OS build, so "whatever was first in the
# list" is not good enough — see the runtime check below.
set -euo pipefail

cd "$(dirname "$0")/.."

# iPhone 16 is the only iPhone present on every runtime we target (18.0 and 26.2),
# so one device name works for both destinations.
DEVICE="${DEVICE:-iPhone 16}"
# 18.0 is IPHONEOS_DEPLOYMENT_TARGET — the floor we actually ship against.
IOS_VERSION="${IOS_VERSION:-18.0}"
PLAN="${PLAN:-Unit}"
RESULT_BUNDLE="${RESULT_BUNDLE:-build/${PLAN}.xcresult}"
# Unset by default: report coverage without gating. CI sets this explicitly.
MIN_COVERAGE="${MIN_COVERAGE:-}"

# Verify the device exists *on that runtime*. Scanning the whole list and taking
# the first hit silently picks an arbitrary runtime, and there is a decoy device
# literally named "iPhone 16 Pro 18.0" that makes bare name matching worse still.
if ! xcrun simctl list devices available \
  | sed -n "/-- iOS ${IOS_VERSION} --/,/^-- /p" \
  | grep -qE "^ +${DEVICE} \("; then
  echo "No available simulator '${DEVICE}' on iOS ${IOS_VERSION}." >&2
  echo "Available on iOS ${IOS_VERSION}:" >&2
  xcrun simctl list devices available \
    | sed -n "/-- iOS ${IOS_VERSION} --/,/^-- /p" \
    | grep -E "^ +iPhone" >&2 || echo "  (no iOS ${IOS_VERSION} runtime installed)" >&2
  exit 1
fi

rm -rf "$RESULT_BUNDLE"
mkdir -p "$(dirname "$RESULT_BUNDLE")"

LOG="build/test-${PLAN}.log"

ARGS=(
  test
  -project WatchTracker.xcodeproj
  -scheme WatchTracker
  -testPlan "$PLAN"
  # OS= plus name= is unambiguous; name= alone is not.
  -destination "platform=iOS Simulator,OS=${IOS_VERSION},name=${DEVICE}"
  -enableCodeCoverage YES
  -resultBundlePath "$RESULT_BUNDLE"
)

for suite in "$@"; do
  ARGS+=(-only-testing:"$suite")
done

echo "Plan: ${PLAN} · ${DEVICE} · iOS ${IOS_VERSION}"

set -o pipefail
if xcodebuild "${ARGS[@]}" 2>&1 | tee "$LOG" | grep -E "error:|' failed|Test Suite|TEST (SUCCEEDED|FAILED)"; then
  :
fi

if ! grep -q "\*\* TEST SUCCEEDED \*\*" "$LOG"; then
  echo
  echo "Failures:"
  grep -E "error:|' failed" "$LOG" | sort -u || true
  exit 1
fi

echo
echo "Coverage:"
xcrun xccov view --report --only-targets "$RESULT_BUNDLE"

if [ -n "$MIN_COVERAGE" ]; then
  COVERAGE=$(xcrun xccov view --report --json "$RESULT_BUNDLE" \
    | python3 -c 'import json,sys; print(round(next(t["lineCoverage"] for t in json.load(sys.stdin)["targets"] if t["name"]=="WatchTracker.app")*100, 2))')
  echo
  echo "WatchTracker.app: ${COVERAGE}% (floor ${MIN_COVERAGE}%)"
  if ! python3 -c "import sys; sys.exit(0 if $COVERAGE >= $MIN_COVERAGE else 1)"; then
    echo "Coverage ${COVERAGE}% is below the ${MIN_COVERAGE}% floor." >&2
    exit 1
  fi
fi
