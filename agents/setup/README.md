# Agent setup

Contracts, prompts, templates, and a research workspace for running several coding agents together: Claude orchestrates, Codex executes, Grok evaluates, Gemini is the fallback. Imported from the former private `omarchy-agent-setup` repository; its history is preserved under this directory.

- `CONTRACTS.md` - who does what, handoff files, and the rules every agent follows. Not the repository contributor guide: that is the root `AGENTS.md`.
- `prompts/` - role prompts for the orchestrator, executor, and evaluator.
- `templates/` - PLAN, TASKS, HANDOFF, ACCEPTANCE, and EVALUATION skeletons.
- `workspace/` - a Hyprland research workspace (Perplexity and Gemini as web apps in separate profiles).

Where Omarchy already covers a piece, use it rather than this directory: `omarchy agent` and `omarchy agent account` for launching and switching subscriptions, `omarchy-launch-terminal-herdr` for the multi-agent layout, `omarchy dictation` and `omarchy studio` for voice. See `plans/agent-setup-roadmap.md` for what is still open.
