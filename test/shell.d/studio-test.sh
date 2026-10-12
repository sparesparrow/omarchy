#!/bin/bash

source "$(dirname "$0")/base-test.sh"

test_bin=$(mktemp -d)
test_home=$(mktemp -d)
log_file=$(mktemp)
trap 'rm -rf "$test_bin" "$test_home"; rm -f "$log_file"' EXIT

cat >"$test_bin/omarchy-agent" <<'EOF2'
#!/bin/bash
echo "cwd:$PWD" >>"$TEST_LOG"
echo "args:$*" >>"$TEST_LOG"
EOF2
cat >"$test_bin/spd-say" <<'EOF2'
#!/bin/bash
echo "spd:$*" >>"$TEST_LOG"
EOF2
chmod +x "$test_bin"/*

run() {
  HOME="$test_home" OMARCHY_PATH="$ROOT" PATH="$test_bin:$ROOT/bin:$PATH" TEST_LOG="$log_file" "$@"
}

run omarchy-studio --lang cs
grep -q "^cwd:$test_home/Studio$" "$log_file" || fail "studio starts in the Studio folder"
grep -q "guide.md" "$log_file" || fail "studio hands the guide to the agent"
grep -q "language is 'cs'" "$log_file" || fail "studio passes the chosen language"
[[ -f $ROOT/default/studio/guide.md ]] || fail "the studio guide ships with Omarchy"
pass "studio launches the agent with the guide"

LANG=de_DE.UTF-8 LC_MESSAGES= run omarchy-studio
grep -q "language is 'de'" "$log_file" || fail "studio derives the language from the locale"
pass "studio derives language from locale"

: >"$log_file"
run omarchy-studio-say --lang cs "Ahoj"
grep -qx 'spd:--wait -l cs -- Ahoj' "$log_file" || fail "say speaks in the requested language"
pass "say speaks in the requested language"

if run omarchy-studio-say 2>/dev/null; then fail "say without text fails"; fi
pass "say requires text"
