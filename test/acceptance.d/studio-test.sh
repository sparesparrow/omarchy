#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

answer_file=$(mktemp)
trap 'omarchy-shell shell hide omarchy.image-picker >/dev/null 2>&1 || true; rm -f "$answer_file"' EXIT

# Studio's questions are answered on picture cards, so the real picker has to
# show them and hand the chosen label back. Speech is a courtesy and may be
# absent in the VM.
omarchy-studio-ask "Do you like it?" "Love it" "It's okay" "Not for me" >"$answer_file" &
ask_pid=$!

wait_until "studio question cards are visible" 20 screen_contains "Love it"
screenshot "success-studio-01-cards"

# Dictation types into the picker's filter; typing stands in for it here.
wtype "Not for"
sleep 1
screenshot "success-studio-02-filtered"
wtype -k Return

wait "$ask_pid"
[[ $(<"$answer_file") == "Not for me" ]] || fail "studio returns the card that was chosen" "$(<"$answer_file")"
pass "studio question cards return the chosen answer"

# The launcher has to resolve its guide inside the installed tree.
[[ -f $OMARCHY_PATH/default/studio/guide.md ]] || fail "studio guide is installed"
pass "studio guide is installed"
