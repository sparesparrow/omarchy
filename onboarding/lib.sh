# shellcheck shell=bash disable=SC2034
# Shared helpers for omarchy-onboard. Safety rules:
# - write only under ~/.config and ~/.local
# - back up before every edit
# - after each Hyprland change: hyprctl reload + configerrors, roll back on error
# - never run sudo; print the command instead

# Deliberately $HOME-based (not XDG_*): writes are restricted to ~/.config and ~/.local.
ONB_CONFIG="$HOME/.config/omarchy-onboarding"
ONB_PROFILE="$ONB_CONFIG/profile.json"
ONB_STATE="$HOME/.local/state/omarchy-onboarding"
ONB_BACKUPS="$ONB_STATE/backups"
ONB_RUN_ID="$(date +%Y%m%d-%H%M%S)"
HYPR_DIR="$HOME/.config/hypr"
ONB_ASSUME_YES="${ONB_ASSUME_YES:-0}"
ONB_NONINTERACTIVE="${ONB_NONINTERACTIVE:-0}"

onb_say() { printf '%s\n' "$*"; }
onb_warn() { printf '! %s\n' "$*" >&2; }

onb_allowed_path() {
  local path
  path="$(realpath -m -- "$1")"
  [[ $path == "$HOME/.config/"* || $path == "$HOME/.local/"* ]]
}

onb_backup() {
  local file="$1" dest
  [[ -e $file ]] || return 0
  dest="$ONB_BACKUPS/$ONB_RUN_ID"
  mkdir -p "$dest"
  cp -a -- "$file" "$dest/${file//\//_}"
  onb_say "$(t notify.backup "$dest/${file//\//_}")"
}

onb_backup_path() {
  printf '%s\n' "$ONB_BACKUPS/$ONB_RUN_ID/${1//\//_}"
}

# onb_confirm "question" -> 0 yes, 1 no. Non-interactive runs answer with ONB_ASSUME_YES.
onb_confirm() {
  local question="$1" answer
  if (( ONB_NONINTERACTIVE )); then
    (( ONB_ASSUME_YES ))
    return
  fi
  if command -v gum >/dev/null 2>&1; then
    gum confirm --affirmative "$(t wizard.yes)" --negative "$(t wizard.no)" "$question"
    return
  fi
  read -r -p "$question [a/N] " answer
  [[ $answer =~ ^[aAyY] ]]
}

# onb_write FILE (content on stdin): backup + write only when the content changed.
onb_write() {
  local file="$1" tmp
  onb_allowed_path "$file" || { onb_warn "refusing to write outside ~/.config or ~/.local: $file"; return 1; }
  tmp="$(mktemp)"
  cat >"$tmp"
  ONB_LAST_CHANGED=0
  if [[ -f $file ]] && cmp -s "$tmp" "$file"; then
    rm -f "$tmp"
    return 0
  fi
  ONB_LAST_CHANGED=1
  ONB_LAST_EXISTED=0
  [[ -e $file ]] && ONB_LAST_EXISTED=1
  mkdir -p "$(dirname "$file")"
  onb_backup "$file"
  cat "$tmp" >"$file"
  rm -f "$tmp"
  onb_say "$(t notify.saved "$file")"
}

onb_hypr_running() {
  command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1
}

ONB_LAST_CHANGED=0
ONB_LAST_EXISTED=0

onb_hypr_errors() {
  hyprctl configerrors 2>/dev/null | tr -d '[:space:]'
}

# onb_hypr_validate FILE ERRORS_BEFORE: reload Hyprland after FILE changed and
# restore FILE if new config errors appeared (pre-existing errors are ignored).
onb_hypr_validate() {
  local file="$1" before="${2:-}" errors backup
  (( ONB_LAST_CHANGED )) || return 0
  if ! onb_hypr_running; then
    onb_say "$(t notify.no_hyprland)"
    return 0
  fi
  hyprctl reload >/dev/null 2>&1 || true
  errors="$(onb_hypr_errors)"
  if [[ -z $errors || $errors == "$before" ]]; then
    onb_say "$(t notify.config_ok)"
    return 0
  fi
  onb_warn "$(t notify.config_error)"
  hyprctl configerrors >&2 || true
  backup="$(onb_backup_path "$file")"
  if (( ONB_LAST_EXISTED )) && [[ -f $backup ]]; then
    cp -a -- "$backup" "$file"
  elif (( ! ONB_LAST_EXISTED )); then
    rm -f -- "$file"
  fi
  hyprctl reload >/dev/null 2>&1 || true
  onb_warn "$(t notify.rolled_back)"
  return 1
}

# onb_lua_block FILE ID (block on stdin): replace a marked block in place or append it.
# Feed it with < <(...) rather than a pipe, so ONB_LAST_CHANGED survives for onb_hypr_validate.
onb_lua_block() {
  local file="$1" id="$2" body tmp bodyf
  local begin="-- >>> omarchy-onboard:$id >>>" end="-- <<< omarchy-onboard:$id <<<"
  body="$(cat)"
  tmp="$(mktemp)"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if grep -qF -- "$begin" "$file"; then
    bodyf="$(mktemp)"
    printf '%s\n' "$body" >"$bodyf"
    awk -v b="$begin" -v e="$end" -v bf="$bodyf" '
      $0==b {print; while ((getline l < bf) > 0) print l; skip=1; next}
      $0==e {skip=0; print; next}
      !skip {print}' "$file" >"$tmp"
    rm -f "$bodyf"
  else
    cat "$file" >"$tmp"
    printf '\n%s\n%s\n%s\n' "$begin" "$body" "$end" >>"$tmp"
  fi
  onb_write "$file" <"$tmp"
  rm -f "$tmp"
}

# Keybinding listing, cached per run. OMARCHY_KEYBINDINGS_FILE overrides it (tests).
onb_keybindings() {
  if [[ -n ${OMARCHY_KEYBINDINGS_FILE:-} ]]; then
    cat -- "$OMARCHY_KEYBINDINGS_FILE"
  elif command -v omarchy >/dev/null 2>&1; then
    omarchy menu keybindings --print 2>/dev/null || true
  fi
}

# onb_chord_owner "SUPER ALT + A" -> prints the description bound to that chord, if any.
onb_chord_owner() {
  local chord="$1"
  onb_keybindings | awk -v c="$chord " 'index($0, c) == 1 { sub(/^[^→]*→[[:space:]]*/, ""); print; exit }'
}

onb_profile_get() {
  local filter="$1"
  [[ -f $ONB_PROFILE ]] || return 1
  jq -r "$filter // empty" "$ONB_PROFILE"
}

onb_has_goal() {
  [[ -f $ONB_PROFILE ]] && jq -e --arg g "$1" '.goals | index($g)' "$ONB_PROFILE" >/dev/null
}

onb_cpu_class() {
  # Prints "weak" or "ok" plus the CPU model on the second line.
  local model cores flags class="ok"
  model="$(awk -F: '/model name/ {sub(/^ /, "", $2); print $2; exit}' /proc/cpuinfo 2>/dev/null)"
  cores="$(nproc 2>/dev/null || echo 1)"
  flags="$(awk -F: '/^flags/ {print $2; exit}' /proc/cpuinfo 2>/dev/null)"
  if (( cores < 4 )) || [[ $model =~ (Atom|Celeron|Pentium\ N|Pentium\ Silver) ]] || [[ $flags != *avx2* ]]; then
    class="weak"
  fi
  printf '%s\n%s\n' "$class" "${model:-unknown}"
}
