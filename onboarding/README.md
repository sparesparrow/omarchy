# Omarchy onboarding (cs)

## Česky

Průvodce pro začátečníky, kteří přecházejí na Omarchy (například z KDE nebo Ubuntu). Vše je přidané navíc: původní soubory Omarchy se nemění. Texty vykají; použité pojmy shrnuje [slovníček](../i18n/cs/GLOSSARY.md).

Spuštění:

```bash
omarchy-onboard            # průvodce: cíle, zkušenosti, denní používání → ~/.config/omarchy-onboarding/profile.json
omarchy-onboard practice   # procvičení klávesových zkratek, které v systému opravdu jsou
omarchy-onboard bindings   # vlastní zkratky (Super + Alt + H procvičování, Super + Alt + J AI lektor)
omarchy-onboard login      # přihlášení k AI účtům přes prohlížeč, postupně jeden po druhém
omarchy-onboard voxtype    # diktování; na slabém procesoru doporučí ponechat angličtinu
omarchy-onboard herdr      # pracovní prostor v Herdru podle profilu
omarchy-onboard plugins    # doporučené doplňky podle cílů (nic neinstaluje)
omarchy-onboard tutor      # trpělivý český AI lektor v nainstalovaném agentovi
omarchy-onboard menu install        # přidá podnabídku „Průvodce pro začátečníky“ do nabídky Omarchy (Super + mezerník)
omarchy-onboard menu remove         # odebere ji
omarchy-onboard firstrun-hook enable|disable|status   # volitelné spuštění po přihlášení (ve výchozím stavu vypnuto)
```

Nabídka: `menu install` upraví jen označený blok (`// >>> omarchy-onboard >>>`) v uživatelském souboru `~/.config/omarchy/extensions/omarchy-menu.jsonc`; ostatní položky zůstanou beze změny. Před zápisem se soubor zálohuje a zkontroluje. Původní `bin/omarchy` ani systémová nabídka se nemění.

První spuštění: `firstrun-hook enable` vytvoří `~/.config/autostart/omarchy-onboard.desktop`, který po přihlášení jednou otevře průvodce – jen dokud neexistuje `profile.json`. Ve výchozím stavu je tato funkce vypnutá. Zda se položky XDG autostart spouštějí, záleží na sezení (uwsm/Hyprland); pokud ne, můžete do `~/.config/hypr/autostart.lua` přidat řádek `omarchy-onboard firstrun`.

Bezpečnost:

- Zapisuje jen do `~/.config` a `~/.local`.
- Před každou úpravou vytvoří zálohu v `~/.local/state/omarchy-onboarding/backups/`.
- Po každé změně nastavení Hyprlandu spustí `hyprctl reload` a `hyprctl configerrors`; pokud se objeví nová chyba, obnoví zálohu.
- Před každou změnou a instalací se zeptá. `sudo` nikdy nespouští sám – jen vypíše příkaz, který můžete spustit vy.
- Nikdy nežádá API klíče a nezapíná placené služby.

Čeština při diktování: vícejazyčný model `base` češtinu zvládá, ale na slabém procesoru (např. Intel Atom) může přepis jedné věty trvat i minuty. Průvodce proto nejdřív zkontroluje procesor a na slabém počítači doporučí ponechat `base.en`.

## English summary

Additive Czech onboarding layer for Omarchy:

- `i18n/`: locale loader (`load.sh`) and Czech strings for menus, notifications, first-boot text and the wizard. Copy `_template/` to add `sk`/`pl`; missing keys fall back to Czech.
- `bin/omarchy-onboard`: beginner wizard that saves `profile.json`, plus subcommands for browser-only AI sign-in, generated Hyprland bindings, a shortcut quiz verified against `omarchy menu keybindings --print`, Voxtype with a CPU-strength check, a starter Herdr layout and a goal-based plugin shortlist.
- `prompts/`: `tutor.md` (Czech, patient, one step at a time), `analyzer.md` (answers into goals and a plan) and `configurator.md` (profile into agent roles). Presets in `prompts/presets/`: `free` (browser login, no API keys) and the optional `pipeline` (Claude/Codex/Grok/Gemini).
- `onboarding/lib.sh`: shared safety helpers (backup, Hyprland validation with rollback, marked Lua blocks, chord checks). `onboarding/plugins.json`: shortlist, including the reviewed rosakodu dock, hyprgrass (needs root for hyprpm) and wvkbd (AUR).
- Touch/rotation/TTS for a specific tablet live in `omarchy-steward/omarchy-steward-setup.sh` (branch `steward-setup`) and are referenced from the shortlist.

Non-interactive example (used by the smoke test):

```bash
omarchy-onboard wizard --non-interactive --goals web,ai --experience none --daily browser --touch no --voice yes --ai yes
```

Menu and first run: `omarchy-onboard menu install|remove` manages a marked "onboard" submenu block in the user extension file `~/.config/omarchy/extensions/omarchy-menu.jsonc` (backed up and validated; upstream `bin/omarchy` untouched). `omarchy-onboard firstrun-hook enable` adds an optional, off-by-default XDG autostart entry that opens the wizard once while no profile exists.
