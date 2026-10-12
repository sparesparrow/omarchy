# i18n

Locale layer for the Czech onboarding (`bin/omarchy-onboard`). It is additive: upstream Omarchy strings are not changed.

- `load.sh`: loader. `omarchy_i18n_load [lang]` fills `MSG`, and `t KEY [args]` prints a string. Czech (`cs`) is the reference locale and the fallback for missing keys.
- `cs/`: Czech strings, split into `menu.sh`, `notifications.sh`, `firstboot.sh` and `onboarding.sh`.
- `_template/`: starting point for new locales (planned: `sk`, `pl`). Czech terminology and form of address: `cs/GLOSSARY.md`.

Add a language: `cp -r i18n/_template i18n/sk`, translate the keys from `i18n/cs/*.sh`, then check with `omarchy-onboard i18n-check sk`.
