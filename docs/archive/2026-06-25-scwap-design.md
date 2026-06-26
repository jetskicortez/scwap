# Super Caveman with a Ponytail — Design Spec

> Historical note: this was the original Claude Code design spec. It is retained for project history, not as launch documentation. Current public support is Claude Code + Codex, with Codex marketplace metadata in `.agents/plugins/marketplace.json` and the installable plugin payload under `plugins/scwap/`. `README.md` is the launch source of truth.

- **Date:** 2026-06-25
- **Status:** Archived — superseded by public launch layout
- **Repo:** `scwap`
- **Plugin / install id:** `scwap` (`scwap@scwap`)
- **Display name:** Super Caveman with a Ponytail

---

## 1. Purpose

A single Claude Code plugin that fuses three MIT-licensed plugins into one composable
operating mode, installed in one step and published as a public GitHub repo with its
own marketplace.

The name encodes the three layers:

- **Super**powers — *process* layer: how the work is approached.
- **Caveman** — *prose* layer: how the agent talks.
- **Ponytail** — *build-constraint* layer: how much gets built.

The value over installing the three separately is the **glue**: a shipped orchestration
rule + skill that makes them behave as one system instead of three coexisting plugins.

## 2. Locked decisions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | Architecture | Unified single plugin (true code merge) | User wants one self-contained, branded plugin. Not a meta-bundle. |
| 2 | Superpowers scope | Vendor full framework now, prune later | Superpowers skills cross-reference each other + auto-load a bootstrap; cherry-picking risks broken links. Ship v1 whole, trim later. |
| 3 | Name | Display "Super Caveman with a Ponytail"; repo + plugin id both `scwap` (short alias) | Encodes all three layers, no collision (avoids jdx/mise). Short slug keeps repo + commands tidy. |
| 4 | Layer interaction | Independent toggles, composed by a flow rule | `/caveman ultra` and `/ponytail off` stay independent; the flow rule ties them conceptually. |

## 3. Concept — three layers, always composed

1. **Process — Superpowers (*how the work is approached*).** Process skills first; they
   decide the approach. brainstorming → writing-plans → test-driven-development →
   systematic-debugging → verification-before-completion → requesting/receiving-code-review.
2. **Build constraint — Ponytail (*how much gets built*).** Always on. YAGNI ladder before
   writing code: needed at all? → already here (reuse)? → stdlib? → native feature? →
   installed dep? → one line? → only then minimal new code. Smallest diff, deletion over
   addition, no unrequested abstractions. Mark shortcuts `// ponytail:`.
3. **Prose — Caveman (*how the agent talks*).** Terse. Drop articles/filler/hedging. Write
   normally for code, commits, security, legal, client-facing output.

**Default build flow:** brainstorm/plan (Superpowers) → decide *what* → build the minimum
(Ponytail) → prove correct with TDD/verification/review (Superpowers).

**Conflict resolution:**
- Test rigor: TDD invoked → TDD governs tests, Ponytail still trims production code. No TDD
  invoked → Ponytail's "one runnable check" default.
- User instructions and host project rules outrank all three layers.
- Never lazy about: understanding the problem, trust-boundary validation, error handling
  that prevents data loss, security, accessibility, anything explicitly requested.

## 4. Repo structure

```
scwap/
├── .claude-plugin/
│   ├── plugin.json            # name: scwap, version, hooks → ./hooks/scwap-hooks.json
│   └── marketplace.json       # /plugin marketplace add <owner>/scwap
├── hooks/
│   ├── scwap-hooks.json       # ONE manifest merging all lifecycle events
│   ├── caveman/               # vendored caveman hook scripts (unchanged)
│   ├── ponytail/              # vendored ponytail hook scripts (unchanged)
│   ├── scwap-statusline.sh    # unified badge (bash)
│   └── scwap-statusline.ps1   # unified badge (PowerShell)
├── skills/
│   ├── caveman*/              # vendored, prefixes kept
│   ├── ponytail*/             # vendored, prefixes kept
│   ├── superpowers/*          # full framework vendored
│   └── scwap-flow/SKILL.md    # NEW — orchestration explainer/activator
├── commands/                  # vendored caveman + ponytail commands
├── rules/
│   └── scwap-flow.md          # the three-layer flow as a portable rule
├── scripts/
│   └── update-vendor.sh       # pull each upstream to a new SHA, re-sync, bump version
├── LICENSE                    # scwap own (MIT)
├── THIRD_PARTY_NOTICES.md     # credits + each upstream LICENSE + pinned SHAs
└── README.md
```

## 5. Component design

### 5.1 Plugin manifest
- `plugin.json`: `name: "scwap"`, `version: "0.1.0"`, `hooks: "./hooks/scwap-hooks.json"`,
  author/description/homepage.
- `marketplace.json`: marketplace `name: "scwap"`, one plugin `scwap`, `source: "./"`,
  category `productivity`.

### 5.2 Hook consolidation
`scwap-hooks.json` registers, per lifecycle event, each vendored script in order. Scripts
stay byte-for-byte from upstream so a sync is a drop-in subtree replace. Flag files remain
independent (`.ponytail-active`, caveman's flag) so toggles don't interfere.

| Event | Scripts (in order) | Effect |
|-------|--------------------|--------|
| SessionStart | ponytail-activate, caveman-activate | Each emits its ruleset as session context; writes its flag file |
| UserPromptSubmit | ponytail-mode-tracker, caveman-mode-tracker | Parse `/ponytail` / `/caveman`, update flag files |
| SubagentStart | ponytail-subagent (+ caveman if present) | Propagate active modes into subagents |

All entries keep `commandWindows` variants and `timeout` ≤ 5s, fail-silent (`exit 0`).

### 5.3 Statusline
`scwap-statusline.{sh,ps1}` composes a badge from the flag files, e.g.
`[SP] [PONY:FULL] [CAVE:ULTRA]`. Inline read (no per-render process spawn). Optional;
documented in README. Host users wire it into their own `statusLine` setting.

### 5.4 Glue (the actual differentiator)
- `rules/scwap-flow.md` — the three-layer flow + conflict resolution as a portable rule,
  so host projects can load it.
- `skills/scwap-flow/SKILL.md` — invokable explainer that states how the layers compose
  and when each leads.

### 5.5 Vendored subtrees
`hooks/{caveman,ponytail}`, `skills/{caveman*,ponytail*,superpowers/*}`, `commands/*` are
copied byte-for-byte from upstream at pinned commits. No edits to vendored files; all
integration lives in scwap-owned files (manifest, hooks manifest, statusline, glue).

## 6. Licensing & attribution

All three upstreams are MIT — redistribution is clean with attribution.

- Preserve each upstream `LICENSE` inside its vendored subtree.
- `THIRD_PARTY_NOTICES.md`: credits + repo links + pinned SHAs for caveman
  (JuliusBrussee/caveman), ponytail (DietrichGebert/ponytail), superpowers (obra/superpowers).
- scwap's own glue code is MIT.

**Pinned SHAs (recorded at build):**
- ponytail: `64adbf9544581e57053a8d84a94e7e4471d40d95` (already cloned locally)
- caveman: upstream HEAD at build time
- superpowers: upstream HEAD at build time

**Source note:** the locally installed superpowers copy comes from
`anthropics/claude-plugins-official` (an Apache-2.0 *directory* repo). superpowers itself is
MIT at `obra/superpowers`. Vendor from `obra/superpowers` to stay MIT-clean and current.

## 7. Sync strategy

Vendor each upstream via `git subtree` pinned to a SHA. `scripts/update-vendor.sh`:
1. Fetch each upstream to a chosen/HEAD SHA.
2. Re-sync the subtree.
3. Bump scwap version.
4. Update the pinned SHAs in `THIRD_PARTY_NOTICES.md`.

Turns "ponytail shipped again" (weekly) into one command.

## 8. Build order (feeds the implementation plan)

1. Scaffold repo + `plugin.json` / `marketplace.json` + `LICENSE` + README skeleton.
2. Vendor the three (subtree; record SHAs).
3. Merge hooks → `scwap-hooks.json`; add unified statusline.
4. Add `scwap-flow` rule + skill.
5. Write README + `THIRD_PARTY_NOTICES.md`.
6. Local install test via registry replication (same method validated for ponytail):
   `marketplaces/` clone + `cache/<sha>/` payload + `known_marketplaces.json` +
   `installed_plugins.json` + `enabledPlugins` toggle.
7. Publish public repo; document `/plugin marketplace add`.

## 9. Testing / acceptance

Local install via registry replication, then:
- SessionStart injects all three rulesets.
- `/caveman` and `/ponytail` toggles are independent; statusline reflects current modes.
- A spawned subagent inherits ponytail + caveman.
- superpowers skills are invokable.
- A fresh third-party clone installs via `/plugin marketplace add` and behaves identically.

## 10. Risks / open items

- **Install-id length** — mitigated by short id `scwap`.
- **Hook perf** — up to ~2–3 node spawns per event; keep timeouts, fail-silent. Acceptable.
- **Superpowers cross-links if pruned later** — deferred; full vendor in v1 avoids it.
- **Upstream drift** — mitigated by `update-vendor.sh`.
- **Windows parity** — confirm caveman + superpowers hooks ship `commandWindows` variants;
  add if missing (scwap-owned wrapper, not an edit to vendored files).
- **Naming collision** — jdx/mise avoided by the chosen name.
