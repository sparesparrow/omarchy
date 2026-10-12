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

# Multilingual dictation: Voxtype's English-only model is replaced once.
cfg_home=$(mktemp -d)
mkdir -p "$cfg_home/voxtype"
printf '[whisper]\nmodel = "base.en"\nlanguage = "en"\n' >"$cfg_home/voxtype/config.toml"
cat >"$test_bin/omarchy-default-dictation" <<'EOF2'
#!/bin/bash
echo voxtype
EOF2
cat >"$test_bin/voxtype" <<'EOF2'
#!/bin/bash
echo "voxtype:$*" >>"$TEST_LOG"
EOF2
cat >"$test_bin/systemctl" <<'EOF2'
#!/bin/bash
echo "systemctl:$*" >>"$TEST_LOG"
EOF2
chmod +x "$test_bin"/*
: >"$log_file"
XDG_CONFIG_HOME="$cfg_home" run omarchy-studio-language
grep -qx 'model = "base"' "$cfg_home/voxtype/config.toml" || fail "English-only model is replaced"
grep -qx 'language = "auto"' "$cfg_home/voxtype/config.toml" || fail "language is detected automatically"
grep -q 'voxtype:setup --download' "$log_file" || fail "multilingual model is downloaded"
: >"$log_file"
XDG_CONFIG_HOME="$cfg_home" run omarchy-studio-language
[[ ! -s $log_file ]] || fail "an already multilingual setup is left alone"
rm -rf "$cfg_home"
pass "studio switches dictation to a multilingual model once"

# Invitation fires once, and only with a default agent.
cat >"$test_bin/omarchy-default-agent" <<'EOF2'
#!/bin/bash
echo claude
EOF2
cat >"$test_bin/omarchy-done" <<'EOF2'
#!/bin/bash
m="$HOME/.m-$2"; [[ -e $m ]] && exit 1; touch "$m"
EOF2
cat >"$test_bin/omarchy-notification-send" <<'EOF2'
#!/bin/bash
echo "notify" >>"$TEST_LOG"
EOF2
chmod +x "$test_bin"/*
: >"$log_file"
run bash "$ROOT/install/user/first-run/setup-studio.hook"
run bash "$ROOT/install/user/first-run/setup-studio.hook"
[[ $(grep -c '^notify$' "$log_file") -eq 1 ]] || fail "studio invitation is sent once"
pass "studio invitation is sent once"

# Ask: cards are made per option and the chosen label comes back.
cat >"$test_bin/omarchy-menu-images" <<'EOF2'
#!/bin/bash
dir=${@: -1}
ls "$dir" >>"$TEST_LOG"
echo "Love it"
EOF2
chmod +x "$test_bin/omarchy-menu-images"
: >"$log_file"
answer=$(run omarchy-studio-ask "Do you like it?" "Love it" "Not for me")
[[ $answer == "Love it" ]] || fail "ask prints the chosen label" "$answer"
grep -qx 'Love it.png' "$log_file" && grep -qx 'Not for me.png' "$log_file" || fail "ask draws a card per option"
if run omarchy-studio-ask "One?" "Only" 2>/dev/null; then fail "ask needs two options"; fi
if run omarchy-studio-ask "Dup?" "A" "A" 2>/dev/null; then fail "ask rejects duplicate labels"; fi
pass "ask shows picture cards and returns the choice"
