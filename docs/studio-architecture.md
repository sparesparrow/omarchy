# ADR: Studio is an agent guide plus small helpers, not a native app

**Status:** Proposed
**Date:** 2026-10-13
**Deciders:** repository owner

## Context

Omarchy Studio should let people who are not programmers, and who may not speak English, build things by talking: answer questions, play quizzes and games, and say how they like each result. Omarchy already has a default agent launcher, dictation backends, an image picker in the Quickshell shell, and a first-run hook mechanism. The question is where the beginner experience should live.

## Decision

Studio is a guide prompt (`default/studio/guide.md`) handed to the user's default agent, plus four small commands: `omarchy studio` (launch), `omarchy studio say` (speech), `omarchy studio ask` (picture-card questions through the existing image picker), and `omarchy studio listen` (hands-free listening that ends on a pause). A hidden `omarchy-studio-language` switches Voxtype to a multilingual model. Nothing new is added to the Quickshell shell.

## Options Considered

### A: Guide prompt and helpers (chosen)
| Dimension | Assessment |
|-----------|------------|
| Complexity | Low: bash and one markdown file |
| Language coverage | Whatever the agent and dictation model speak |
| Reuse | Default agent, `omarchy-dictation`, `omarchy-menu-images`, first-run hooks |
| Verification | Helpers stub-testable; end to end needs a real desktop |

**Pros:** works with any agent, every language the model handles, tiny to maintain, no new UI to keep in sync with upstream.
**Cons:** behavior depends on the agent following the guide; the quiz and game quality is the agent's, not ours; agents run unattended in their auto-approve modes.

### B: Native Quickshell Studio panel
**Pros:** consistent visuals, deterministic quiz and rating flows, works without a terminal.
**Cons:** large QML surface to maintain against upstream, localization of every string, and it still needs an agent behind it.

### C: Standalone app
**Pros:** full control of the experience.
**Cons:** duplicates the agent, dictation, and picker stacks; furthest from the fork's upstream.

## Trade-off Analysis

A gives the fastest path to something testable and keeps the fork close to upstream. B only pays off once real users show the card picker and a terminal-hosted agent are not enough. The deciding factor is that nothing has yet been observed with a real non-programmer, so the heaviest option would be built on guesses.

## Consequences

- Easier: adding languages (none to add), swapping agents, upgrading the guide.
- Harder: guaranteeing consistent quiz and rating behavior; the hands-free loop depends on Voxtype typing into the focused window and on `ffmpeg` hearing a pause.
- Revisit: after the first live session with a non-programmer, and before any native panel; sign-in to an agent still needs a person.

## Action Items

1. [ ] Run `omarchy studio` and `test/acceptance.d/studio-test.sh` on a real Omarchy desktop and record what breaks.
2. [ ] Watch a non-programmer use it in a language other than English and note where they stall.
3. [ ] Decide on a native panel only from those observations.
