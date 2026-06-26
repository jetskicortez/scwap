# Super Caveman with a Ponytail (scwap)

One plugin, three composable layers: structured process, build restraint, and disciplined prose — all working together.

---

## Support

| Host | Status | Notes |
|---|---|---|
| Claude Code | Supported | Installs through Claude Code's plugin marketplace flow. Hooks provide startup context, `/ponytail` and `/caveman` toggles, and optional statusline support. |
| Codex | Supported | Installs through Codex's plugin marketplace flow. Skills load as `scwap:*`; hooks require explicit Codex trust before startup context runs. |
| Gemini / Copilot | Not shipped | Deferred until those harnesses have verified plugin or instruction-loading paths. |

`README.md` is the public launch source of truth. Files under `docs/archive/` are historical implementation notes and may describe superseded layouts.

---

## The Three Layers

| Layer | Source | Controls |
|---|---|---|
| **Superpowers** | obra/superpowers | *Process* — how work is approached (plan, TDD, verify, review) |
| **Ponytail** | DietrichGebert/ponytail | *Build restraint* — how much gets built (scope gates, debt tracking) |
| **Caveman** | JuliusBrussee/caveman | *Prose* — how the agent talks (direct, no fluff, no filler) |

Each layer is independently togglable. Together they enforce a complete discipline: think before building, build the minimum, prove it works.

---

## Default Build Flow

```
brainstorm / plan  →  build the minimum  →  prove correct (TDD / verify / review)
```

Mapped to bundled skills: `brainstorming` + `writing-plans` → build → `test-driven-development` + `verification-before-completion` + `requesting-code-review`. In Codex, those appear with the plugin prefix, e.g. `scwap:brainstorming`.

The `/scwap-flow` skill documents how the layers compose and which one leads. `rules/scwap-flow.md` is a portable rule you can drop into a project's instructions (e.g. `CLAUDE.md`) to make the sequence explicit for that project.

---

## Install

### Claude Code

Send these as two separate prompts, then restart Claude Code so hooks load:

```
/plugin marketplace add jetskicortez/scwap
/plugin install scwap@scwap
```

After restart, the status badge appears and all three layers are active at their default levels.

### Codex

Add the marketplace, install/enable `scwap@scwap` from Codex's plugin UI, review/trust the plugin hooks when Codex prompts, then start a new Codex session:

```
codex plugin marketplace add jetskicortez/scwap
```

Codex loads all three layers from plugin hooks. No global `~/.codex/AGENTS.md` block is required. Codex hook trust is explicit by design; if hooks are not trusted yet, run `/hooks` in Codex and approve the current scwap hook definitions.

Windows Codex CLI 0.125 note: if Git fails while cloning a `\\?\...` temp path, clone the repo yourself and add that local path instead:

```
git clone https://github.com/jetskicortez/scwap.git scwap
codex plugin marketplace add ./scwap
```

## Maintainer Notes

`scripts/local-install-claude-dev.sh` is maintainer-only registry replication tooling for Claude Code smoke tests. Public users should use the install commands above.

---

## Toggles

**Ponytail** — controls build-scope discipline:
```
/ponytail lite
/ponytail full
/ponytail ultra
/ponytail off
```

**Caveman** — controls prose register:
```
/caveman lite
/caveman full
/caveman ultra
/caveman off
```

Superpowers process is always on while scwap is installed. Toggle ponytail and caveman independently based on context.

---

## Statusline (optional)

Wire the statusline hook to show a live badge — `[SP] [PONY:x] [CAVE:x]` — in Claude Code's status bar.

**macOS / Linux** — add to your `statusLine` setting:
```
hooks/scwap-statusline.sh
```

**Windows** — use the PowerShell variant:
```
hooks/scwap-statusline.ps1
```

The badge reflects the current mode of each layer at a glance.

---

## Credits / License

scwap is MIT licensed. It bundles three MIT-licensed projects — full attribution in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

- **obra/superpowers** — the process skeleton every session runs on
- **DietrichGebert/ponytail** — the build-restraint layer that keeps scope honest
- **JuliusBrussee/caveman** — the prose layer that keeps the agent direct
