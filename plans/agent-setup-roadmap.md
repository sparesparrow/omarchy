# Agent setup roadmap

Carried over from the private agent-setup repository's issues #1-#18. Items Omarchy already covers are marked.

## Phase 1: Foundations
- [x] Agent contracts: `agents/setup/CONTRACTS.md`, prompts, templates
- [ ] Research workspace launcher: `agents/setup/workspace/` (review before relying on it)

## Phase 2: Research pipeline
- [ ] Playwright MCP for Codex
- [ ] Research dispatcher
- [ ] Research synthesis step
- [ ] Prompt-injection guard for research output

## Phase 3: Routing and desktop
- [ ] Quota-fallback router
- [x] Herdr layout: covered by the built-in herdr launchers and config
- [ ] Omarchy Steward OMP profile
- [ ] Personal keybinding cheat sheet (see `omarchy menu keybindings`)
- [~] Voice dictation: `omarchy dictation` and `omarchy studio` exist; a no-local-model option for old hardware means choosing Superwhisper over Voxtype

## Phase 4: Hardening and polish
- [ ] Backup and recovery for `~/.config`
- [ ] Quota tracker (partly covered by `omarchy agent usage-update`)
- [ ] Repo-aware plan templates
- [ ] PR automation with Grok evaluation
- [ ] Older-hardware profiling of the research workspace
- [~] Learning curriculum: the Studio guide and the Czech tutor cover the beginner path
