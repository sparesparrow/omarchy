# shellcheck shell=bash
# Omarchy onboarding locale loader. Source this file, then call:
#   omarchy_i18n_load [lang]   # lang defaults to $OMARCHY_LANG, then $LANG, then cs
#   t KEY [printf-args...]     # print the translated string (falls back to cs, then the key)
#
# Locales live in i18n/<lang>/*.sh and fill the associative array MSG.
# Add a language by copying i18n/_template/ to i18n/<lang>/ and translating.

declare -gA MSG=()
declare -g OMARCHY_I18N_LANG=""
OMARCHY_I18N_DIR="${OMARCHY_I18N_DIR:-$(dirname "${BASH_SOURCE[0]}")}"

omarchy_i18n_detect() {
  local lang="${OMARCHY_LANG:-${LANG:-}}"
  lang="${lang%%.*}"
  lang="${lang%%_*}"
  if [[ -n $lang && -d $OMARCHY_I18N_DIR/$lang ]]; then
    printf '%s\n' "$lang"
  else
    printf '%s\n' "cs"
  fi
}

omarchy_i18n_load() {
  local lang="${1:-$(omarchy_i18n_detect)}" file
  MSG=()
  # Czech is the reference locale; it is loaded first so missing keys fall back to it.
  for file in "$OMARCHY_I18N_DIR"/cs/*.sh; do
    # shellcheck source=/dev/null
    source "$file"
  done
  if [[ $lang != "cs" && -d $OMARCHY_I18N_DIR/$lang ]]; then
    for file in "$OMARCHY_I18N_DIR/$lang"/*.sh; do
      # shellcheck source=/dev/null
      source "$file"
    done
  fi
  # shellcheck disable=SC2034  # read by callers
  OMARCHY_I18N_LANG="$lang"
}

t() {
  local key="$1"
  shift
  local fmt="${MSG[$key]:-$key}"
  # shellcheck disable=SC2059  # translations are trusted format strings
  printf "$fmt" "$@"
}
