# Omarchy onboarding (cs)

## Česky

Průvodce pro začátečníky, kteří přecházejí na Omarchy (třeba z KDE nebo Ubuntu). Vše je doplněk: původní soubory Omarchy se nemění.

Spuštění:

```bash
omarchy-onboard            # průvodce: cíle, zkušenosti, denní používání → ~/.config/omarchy-onboarding/profile.json
omarchy-onboard practice   # procvičení zkratek, které v systému opravdu jsou
omarchy-onboard bindings   # osobní zkratky (Super + Alt + H procvičování, Super + Alt + J AI lektor)
omarchy-onboard login      # přihlášení AI účtů přes prohlížeč, jeden po druhém
omarchy-onboard voxtype    # diktování; na slabém procesoru doporučí angličtinu
omarchy-onboard herdr      # základní plocha v Herdru podle profilu
omarchy-onboard plugins    # doporučené doplňky podle cílů (nic neinstaluje)
omarchy-onboard tutor      # trpělivý český AI lektor v nainstalovaném agentovi
```

Bezpečnost:

- Zapisuje jen do `~/.config` a `~/.local`.
- Před úpravou vždy zálohuje do `~/.local/state/omarchy-onboarding/backups/`.
- Po každé změně Hyprlandu spustí `hyprctl reload` a `hyprctl configerrors`; při nové chybě vrátí zálohu.
- Před instalací se ptá; `sudo` nikdy nespouští sám, jen vypíše příkaz.
- Nikdy nežádá API klíče a nezapíná placené použití.

Čeština v diktování: vícejazyčný model `base` umí česky, ale na slabém procesoru (např. Intel Atom) trvá přepis věty i minuty. Průvodce proto zkontroluje procesor a na slabém stroji nechá `base.en`.

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
