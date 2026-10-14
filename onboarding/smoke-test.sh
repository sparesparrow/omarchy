#!/bin/bash

# Smoke test for omarchy-onboard in a throwaway HOME. No real system changes:
# hyprctl and omarchy are stubbed; the stub hyprctl reports a config error when
# a bindings.lua contains "BREAK_ME" so the rollback path is exercised.

set -euo pipefail

ROOT="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# XDG_* point elsewhere on purpose: writes must follow $HOME (regression seen on a real tablet).
export HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/xdg-config" XDG_STATE_HOME="$TMP/xdg-state"
mkdir -p "$HOME/.config/hypr" "$TMP/bin"

cat >"$TMP/bin/hyprctl" <<'STUB'
#!/bin/bash
case $1 in
  version|reload) exit 0 ;;
  configerrors) grep -q BREAK_ME "$HOME/.config/hypr/bindings.lua" 2>/dev/null && echo "bindings.lua:1: error" ; exit 0 ;;
esac
STUB
chmod +x "$TMP/bin/hyprctl"
export PATH="$TMP/bin:$PATH"

cat >"$TMP/keybindings.txt" <<'KB'
SUPER + SPACE                       → Omarchy menu
SUPER + RETURN                      → Terminal
SUPER SHIFT + RETURN                → Browser
SUPER + K                           → Keybindings
SUPER + W                           → Close window
SUPER + Q                           → Close window
SUPER ALT + J                       → Something else
KB
export OMARCHY_KEYBINDINGS_FILE="$TMP/keybindings.txt"

ob() { "$ROOT/bin/omarchy-onboard" "$@"; }
pass() { printf 'PASS %s\n' "$*"; }
fail() { printf 'FAIL %s\n' "$*"; exit 1; }

ob wizard --non-interactive --goals web,ai --experience none --daily browser --touch no --voice yes --ai yes >"$TMP/wizard.out"
profile="$HOME/.config/omarchy-onboarding/profile.json"
if jq -e '.lang == "cs" and (.goals | index("ai")) and (.goals | index("voice")) and .experience == "none" and .ai_preset == "free"' "$profile" >/dev/null; then pass "wizard wrote profile.json"; else fail "profile content"; fi
if grep -q "Průvodce Omarchy" "$TMP/wizard.out"; then pass "Czech wizard text"; else fail "Czech text"; fi

ONB_NONINTERACTIVE=1 ob practice >"$TMP/practice.out"
if grep -q "otevřít terminál = SUPER + RETURN" "$TMP/practice.out"; then pass "practice reads real bindings"; else fail "practice"; fi
if grep -q "Tyto zkratky ve vašem systému nejsou" "$TMP/practice.out"; then pass "practice reports missing shortcuts"; else fail "practice missing"; fi

printf -- '-- user file\n' >"$HOME/.config/hypr/bindings.lua"
ONB_NONINTERACTIVE=1 ONB_ASSUME_YES=1 ob bindings >"$TMP/bindings.out"
if grep -q 'SUPER + ALT + H' "$HOME/.config/hypr/bindings.lua"; then pass "bindings block written"; else fail "bindings block"; fi
if grep -q 'AI lektor' "$HOME/.config/hypr/bindings.lua"; then fail "taken chord was bound"; else pass "taken chord SUPER ALT + J skipped"; fi
if ls "$HOME/.local/state/omarchy-onboarding/backups/"*/* >/dev/null; then pass "backup created"; else fail "backup"; fi
cp "$HOME/.config/hypr/bindings.lua" "$TMP/before.lua"
ONB_NONINTERACTIVE=1 ONB_ASSUME_YES=1 ob bindings >/dev/null
if cmp -s "$TMP/before.lua" "$HOME/.config/hypr/bindings.lua"; then pass "bindings idempotent"; else fail "not idempotent"; fi

# Rollback: a block containing BREAK_ME makes the stub report a config error.
cp "$HOME/.config/hypr/bindings.lua" "$TMP/good.lua"
( export ONB_NONINTERACTIVE=1 ONB_ASSUME_YES=1
  # shellcheck source=/dev/null
  source "$ROOT/i18n/load.sh"; omarchy_i18n_load cs
  # shellcheck source=/dev/null
  source "$ROOT/onboarding/lib.sh"
  onb_lua_block "$HOME/.config/hypr/bindings.lua" breaker < <(printf -- '-- BREAK_ME\n')
  onb_hypr_validate "$HOME/.config/hypr/bindings.lua" "" ) >/dev/null 2>&1 || true
if cmp -s "$TMP/good.lua" "$HOME/.config/hypr/bindings.lua"; then pass "config error rolled back"; else fail "rollback"; fi

ob plugins >"$TMP/plugins.out"
if grep -q "Agents bar widget" "$TMP/plugins.out"; then pass "plugin shortlist by goal"; else fail "plugins"; fi

if ob prompt tutor | grep '"experience": "none"'>/dev/null; then pass "tutor prompt includes profile"; else fail "prompt"; fi
if ob i18n-check cs 2>&1 | grep "missing: 0">/dev/null; then pass "cs locale complete"; else fail "i18n"; fi

menu="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
mkdir -p "$(dirname "$menu")"
printf '{\n  // user comment\n  "personal": {"icon":"x","label":"P"}\n}\n' >"$menu"
ob menu install >/dev/null
if sed -E 's#(^|[[:space:]])//.*$##' "$menu" | tr '\n' ' ' | sed -E 's/,[[:space:]]*([]}])/\1/g' | jq -e '.["onboard.practice"].action and .personal' >/dev/null; then pass "menu entry added, user entries kept"; else fail "menu install"; fi
cp "$menu" "$TMP/menu1"; ob menu install >/dev/null
if cmp -s "$TMP/menu1" "$menu"; then pass "menu install idempotent"; else fail "menu idempotent"; fi
ob menu remove >/dev/null
if grep -q onboard "$menu" || ! grep -q personal "$menu"; then fail "menu remove"; else pass "menu remove leaves user entries"; fi
if ob firstrun-hook status | grep vypnuto >/dev/null && [[ ! -e $HOME/.config/autostart/omarchy-onboard.desktop ]]; then pass "first-run hook off by default"; else fail "firstrun default"; fi
ob firstrun-hook enable >/dev/null; ob firstrun-hook disable >/dev/null
if [[ ! -e $HOME/.config/autostart/omarchy-onboard.desktop ]]; then pass "first-run hook enable/disable"; else fail "firstrun toggle"; fi
if [[ -e $TMP/xdg-config || -e $TMP/xdg-state ]]; then fail "wrote to XDG_* outside HOME"; else pass "ignores foreign XDG_* dirs"; fi

if find "$HOME" -newer "$TMP/keybindings.txt" -type f | grep -vE "^$HOME/\.(config|local)/"; then fail "wrote outside ~/.config or ~/.local"; else pass "writes only under ~/.config and ~/.local"; fi
echo "ALL PASS"
