#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# The onboarding smoke test runs against a throwaway HOME and a fake Hyprland.
if bash "$ROOT/onboarding/smoke-test.sh" >/dev/null 2>&1; then
  pass "onboarding smoke test passes"
else
  fail "onboarding smoke test passes" "$(bash "$ROOT/onboarding/smoke-test.sh" 2>&1 | tail -20)"
fi

if "$ROOT/bin/omarchy-onboard" prompt ../README >/dev/null 2>&1; then
  fail "prompt rejects path traversal"
else
  pass "prompt rejects path traversal"
fi

if grep -q 'GROUP_DESCRIPTIONS\[onboard\]' "$ROOT/bin/omarchy"; then
  pass "onboard command group is described"
else
  fail "onboard command group is described"
fi
