# Super Caveman with a Ponytail (scwap) Implementation Plan

> Historical note: this was the original implementation plan. It is retained for project history, not as launch documentation. It contains superseded Claude-only assumptions such as `source: "./"` and gated publishing. Current public support is Claude Code + Codex; `README.md` is the launch source of truth.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `scwap`, one Claude Code plugin that vendors superpowers + ponytail + caveman and adds the three-layer orchestration glue, published as a public GitHub repo with its own marketplace.

**Architecture:** Vendor each upstream's hook scripts, skills, and commands byte-for-byte into a single plugin. One merged `hooks/scwap-hooks.json` runs each upstream's lifecycle hooks per event. A unified statusline composes the existing per-plugin badges. The differentiator is scwap-owned glue: a `scwap-flow` rule + skill encoding how the three layers compose.

**Tech Stack:** Claude Code plugin format (`.claude-plugin/`), Node.js (vendored hooks + Node's built-in `node --test` runner, no test framework), Bash + PowerShell (statusline + scripts), `git subtree`-style vendoring, `gh` for publish.

---

## Layout note (supersedes spec §4 tree)

Hooks and skills are **flat**, not nested per-plugin:

- `hooks/` holds all scripts directly (`ponytail-activate.js`, `caveman-activate.js`, superpowers `run-hook.cmd` + `session-start/`, etc.). Vendored scripts hardcode `${CLAUDE_PLUGIN_ROOT}/hooks/<script>` and ponytail's `ponytail-instructions.js` resolves `__dirname/../skills/ponytail/SKILL.md`. Nesting under `hooks/ponytail/` would break both. Filenames are prefix-unique, so no collisions.
- `skills/` holds every skill directly (`skills/ponytail/`, `skills/brainstorming/`, `skills/caveman/`, …). Claude Code discovers plugin skills at `skills/<name>/SKILL.md`. No name collisions across the three sets.
- Per-upstream licenses go in `licenses/LICENSE-<name>` (subtrees aren't isolated dirs).

## Working branch

All implementation commits land on a feature branch (the spec lives on `docs/design-spec`):

```bash
cd /c/Users/Jetsk/Code/scwap
git checkout -b feature/scwap-v1
```

Run all `git` and `node` commands from **Git Bash** in `/c/Users/Jetsk/Code/scwap`. Node v24 is installed.

---

## Task 1: Plugin manifests, license, test harness

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`
- Create: `LICENSE`
- Create: `.gitignore`
- Test: `tests/structure.test.mjs`

- [ ] **Step 1: Write the failing test**

Create `tests/structure.test.mjs`:

```javascript
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';

const root = new URL('../', import.meta.url).pathname;
const read = (p) => readFileSync(root + p, 'utf8');
const json = (p) => JSON.parse(read(p));

test('plugin.json valid + required fields', () => {
  const p = json('.claude-plugin/plugin.json');
  assert.equal(p.name, 'scwap');
  assert.match(p.version, /^\d+\.\d+\.\d+$/);
  assert.equal(p.hooks, './hooks/scwap-hooks.json');
});

test('marketplace.json valid + lists scwap plugin', () => {
  const m = json('.claude-plugin/marketplace.json');
  assert.equal(m.name, 'scwap');
  assert.ok(m.plugins.some((x) => x.name === 'scwap'));
});

test('LICENSE present', () => {
  assert.ok(existsSync(root + 'LICENSE'));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/`
Expected: FAIL — `ENOENT` opening `.claude-plugin/plugin.json`.

- [ ] **Step 3: Create the manifests + license + gitignore**

`.claude-plugin/plugin.json`:
```json
{
  "name": "scwap",
  "version": "0.1.0",
  "description": "Super Caveman with a Ponytail — one plugin, three composable layers: process (Superpowers), build restraint (Ponytail), terse prose (Caveman).",
  "author": { "name": "Jesse Cortez" },
  "homepage": "https://github.com/jetskicortez/scwap",
  "license": "MIT",
  "hooks": "./hooks/scwap-hooks.json"
}
```

`.claude-plugin/marketplace.json`:
```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "scwap",
  "description": "Super Caveman with a Ponytail — superpowers + ponytail + caveman, fused.",
  "owner": { "name": "Jesse Cortez", "url": "https://github.com/jetskicortez" },
  "plugins": [
    {
      "name": "scwap",
      "description": "Process + build-restraint + terse-prose layers in one install.",
      "source": "./",
      "category": "productivity"
    }
  ]
}
```

`LICENSE`: standard MIT text, copyright line `Copyright (c) 2026 Jesse Cortez`.

`.gitignore`:
```
node_modules/
.DS_Store
*.log
_local-install/
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test tests/`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin LICENSE .gitignore tests/structure.test.mjs
git commit -m "feat: scaffold scwap plugin manifests + test harness"
```

---

## Task 2: Vendor ponytail (flat hooks, skills, commands, license)

Source: existing clone at `/c/Users/Jetsk/Code/_ponytail-scan` (pinned SHA `64adbf9544581e57053a8d84a94e7e4471d40d95`).

**Files:**
- Create: `hooks/ponytail-activate.js`, `ponytail-mode-tracker.js`, `ponytail-subagent.js`, `ponytail-config.js`, `ponytail-runtime.js`, `ponytail-instructions.js`, `ponytail-statusline.sh`, `ponytail-statusline.ps1`
- Create: `skills/ponytail/`, `skills/ponytail-audit/`, `skills/ponytail-debt/`, `skills/ponytail-gain/`, `skills/ponytail-help/`, `skills/ponytail-review/`
- Create: `commands/ponytail*.toml`, `licenses/LICENSE-ponytail`
- Test: append to `tests/structure.test.mjs`

- [ ] **Step 1: Write the failing test (append)**

Append to `tests/structure.test.mjs`:

```javascript
test('ponytail hooks vendored', () => {
  for (const f of ['ponytail-activate.js', 'ponytail-mode-tracker.js',
    'ponytail-subagent.js', 'ponytail-config.js', 'ponytail-runtime.js',
    'ponytail-instructions.js']) {
    assert.ok(existsSync(root + 'hooks/' + f), 'missing hooks/' + f);
  }
});

test('ponytail skills vendored + instruction path resolves', () => {
  assert.ok(existsSync(root + 'skills/ponytail/SKILL.md'));
  for (const s of ['ponytail-audit', 'ponytail-debt', 'ponytail-gain',
    'ponytail-help', 'ponytail-review']) {
    assert.ok(existsSync(root + 'skills/' + s + '/SKILL.md'), 'missing ' + s);
  }
});

test('ponytail license vendored', () => {
  assert.ok(existsSync(root + 'licenses/LICENSE-ponytail'));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/`
Expected: FAIL on the three new tests (`missing hooks/ponytail-activate.js`).

- [ ] **Step 3: Copy the vendored files**

```bash
cd /c/Users/Jetsk/Code/scwap
SRC=/c/Users/Jetsk/Code/_ponytail-scan
mkdir -p hooks skills commands licenses
cp "$SRC"/hooks/ponytail-activate.js "$SRC"/hooks/ponytail-mode-tracker.js \
   "$SRC"/hooks/ponytail-subagent.js "$SRC"/hooks/ponytail-config.js \
   "$SRC"/hooks/ponytail-runtime.js "$SRC"/hooks/ponytail-instructions.js \
   "$SRC"/hooks/ponytail-statusline.sh "$SRC"/hooks/ponytail-statusline.ps1 hooks/
for s in ponytail ponytail-audit ponytail-debt ponytail-gain ponytail-help ponytail-review; do
  mkdir -p "skills/$s"; cp "$SRC/.openclaw/skills/$s/SKILL.md" "skills/$s/SKILL.md"
done
cp "$SRC"/commands/ponytail*.toml commands/
cp "$SRC"/LICENSE licenses/LICENSE-ponytail
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test tests/`
Expected: PASS (all ponytail tests green).

- [ ] **Step 5: Commit**

```bash
git add hooks skills commands licenses
git commit -m "feat: vendor ponytail (hooks, skills, commands) @64adbf95"
```

---

## Task 3: Vendor caveman

Source: clone `JuliusBrussee/caveman` fresh to capture its SHA.

**Files:**
- Create: `hooks/caveman-activate.js`, `caveman-config.js`, `caveman-mode-tracker.js`, `caveman-statusline.sh`, `caveman-statusline.ps1`
- Create: `skills/caveman/`, `caveman-commit/`, `caveman-help/`, `caveman-review/`, `compress/`
- Create: `commands/caveman*.toml`, `licenses/LICENSE-caveman`
- Test: append to `tests/structure.test.mjs`

- [ ] **Step 1: Write the failing test (append)**

```javascript
test('caveman hooks vendored', () => {
  for (const f of ['caveman-activate.js', 'caveman-config.js',
    'caveman-mode-tracker.js']) {
    assert.ok(existsSync(root + 'hooks/' + f), 'missing hooks/' + f);
  }
});

test('caveman skills vendored', () => {
  for (const s of ['caveman', 'caveman-commit', 'caveman-help',
    'caveman-review', 'compress']) {
    assert.ok(existsSync(root + 'skills/' + s + '/SKILL.md'), 'missing ' + s);
  }
});

test('caveman license vendored', () => {
  assert.ok(existsSync(root + 'licenses/LICENSE-caveman'));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/`
Expected: FAIL on the three new caveman tests.

- [ ] **Step 3: Clone + copy, record SHA**

```bash
cd /c/Users/Jetsk/Code
git clone --depth 1 https://github.com/JuliusBrussee/caveman.git _caveman-vendor
CAVE_SHA=$(git -C _caveman-vendor rev-parse HEAD); echo "caveman SHA: $CAVE_SHA"
cd /c/Users/Jetsk/Code/scwap
C=/c/Users/Jetsk/Code/_caveman-vendor
cp "$C"/hooks/caveman-activate.js "$C"/hooks/caveman-config.js \
   "$C"/hooks/caveman-mode-tracker.js "$C"/hooks/caveman-statusline.sh \
   "$C"/hooks/caveman-statusline.ps1 hooks/
for s in caveman caveman-commit caveman-help caveman-review compress; do
  mkdir -p "skills/$s"; cp -r "$C/skills/$s/." "skills/$s/"
done
cp "$C"/commands/caveman*.toml commands/
cp "$C"/LICENSE licenses/LICENSE-caveman
```

Record `$CAVE_SHA` — used in Task 8 (THIRD_PARTY_NOTICES).

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test tests/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add hooks skills commands licenses
git commit -m "feat: vendor caveman (hooks, skills, commands)"
```

---

## Task 4: Vendor superpowers (from obra/superpowers, MIT)

Source: clone `obra/superpowers` (MIT — NOT the Apache directory repo). Vendor whole `skills/` + `hooks/` (full-now-prune-later, decision #2).

**Files:**
- Create: `hooks/run-hook.cmd`, `hooks/session-start/` (+ any sibling hook assets)
- Create: `skills/<14 superpowers skills>/`
- Create: `licenses/LICENSE-superpowers`
- Test: append to `tests/structure.test.mjs`

- [ ] **Step 1: Write the failing test (append)**

```javascript
test('superpowers core skills vendored', () => {
  for (const s of ['brainstorming', 'writing-plans', 'test-driven-development',
    'systematic-debugging', 'verification-before-completion',
    'requesting-code-review', 'using-superpowers']) {
    assert.ok(existsSync(root + 'skills/' + s + '/SKILL.md'), 'missing ' + s);
  }
});

test('superpowers session-start hook vendored', () => {
  assert.ok(existsSync(root + 'hooks/run-hook.cmd'));
  assert.ok(existsSync(root + 'hooks/session-start'));
});

test('superpowers license vendored', () => {
  assert.ok(existsSync(root + 'licenses/LICENSE-superpowers'));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/`
Expected: FAIL on the three new superpowers tests.

- [ ] **Step 3: Clone + copy, record SHA**

```bash
cd /c/Users/Jetsk/Code
git clone --depth 1 https://github.com/obra/superpowers.git _superpowers-vendor
SP_SHA=$(git -C _superpowers-vendor rev-parse HEAD); echo "superpowers SHA: $SP_SHA"
cd /c/Users/Jetsk/Code/scwap
S=/c/Users/Jetsk/Code/_superpowers-vendor
# skills (all 14) — flat
cp -r "$S"/skills/. skills/
# hooks: run-hook.cmd + session-start/ (+ any other non-json hook assets)
cp "$S"/hooks/run-hook.cmd hooks/ 2>/dev/null || true
cp -r "$S"/hooks/session-start hooks/session-start
cp "$S"/LICENSE licenses/LICENSE-superpowers
```

Record `$SP_SHA` — used in Task 8.
Note: superpowers' own `hooks/hooks.json` is NOT copied — its SessionStart entry is merged into `scwap-hooks.json` in Task 5 instead.

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test tests/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add hooks skills licenses
git commit -m "feat: vendor obra/superpowers full skill framework"
```

---

## Task 5: Merged hooks manifest

Combine all three upstreams' lifecycle hooks into one `hooks/scwap-hooks.json`. Order per event: ponytail → caveman → superpowers (superpowers only registers SessionStart).

**Files:**
- Create: `hooks/scwap-hooks.json`
- Test: append to `tests/structure.test.mjs`

- [ ] **Step 1: Write the failing test (append)**

```javascript
test('scwap-hooks.json valid; every referenced script exists', () => {
  const h = json('hooks/scwap-hooks.json');
  const events = Object.values(h.hooks).flat();
  const cmds = events.flatMap((e) => e.hooks).map((x) => x.command);
  // pull "${CLAUDE_PLUGIN_ROOT}/hooks/<file>" targets and assert presence
  for (const c of cmds) {
    const m = c.match(/hooks\/([A-Za-z0-9._-]+(?:\/[A-Za-z0-9._-]+)?)/);
    if (m) assert.ok(existsSync(root + 'hooks/' + m[1]), 'missing referenced ' + m[1]);
  }
  assert.ok(h.hooks.SessionStart.length >= 1);
  assert.ok(h.hooks.UserPromptSubmit.length >= 1);
  assert.ok(h.hooks.SubagentStart.length >= 1);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/`
Expected: FAIL — `ENOENT` on `hooks/scwap-hooks.json`.

- [ ] **Step 3: Create `hooks/scwap-hooks.json`**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          { "type": "command",
            "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/ponytail-activate.js\"; exit 0",
            "commandWindows": "if (Get-Command node -ErrorAction SilentlyContinue) { node \"$env:CLAUDE_PLUGIN_ROOT\\hooks\\ponytail-activate.js\" }",
            "timeout": 5, "statusMessage": "Loading ponytail..." },
          { "type": "command",
            "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/caveman-activate.js\"; exit 0",
            "commandWindows": "if (Get-Command node -ErrorAction SilentlyContinue) { node \"$env:CLAUDE_PLUGIN_ROOT\\hooks\\caveman-activate.js\" }",
            "timeout": 5, "statusMessage": "Loading caveman..." },
          { "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start",
            "async": false, "timeout": 10, "statusMessage": "Loading superpowers..." }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command",
            "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/ponytail-mode-tracker.js\"; exit 0",
            "commandWindows": "if (Get-Command node -ErrorAction SilentlyContinue) { node \"$env:CLAUDE_PLUGIN_ROOT\\hooks\\ponytail-mode-tracker.js\" }",
            "timeout": 5 },
          { "type": "command",
            "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/caveman-mode-tracker.js\"; exit 0",
            "commandWindows": "if (Get-Command node -ErrorAction SilentlyContinue) { node \"$env:CLAUDE_PLUGIN_ROOT\\hooks\\caveman-mode-tracker.js\" }",
            "timeout": 5 }
        ]
      }
    ],
    "SubagentStart": [
      {
        "hooks": [
          { "type": "command",
            "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/ponytail-subagent.js\"; exit 0",
            "commandWindows": "if (Get-Command node -ErrorAction SilentlyContinue) { node \"$env:CLAUDE_PLUGIN_ROOT\\hooks\\ponytail-subagent.js\" }",
            "timeout": 5 }
        ]
      }
    ]
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test tests/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add hooks/scwap-hooks.json tests/structure.test.mjs
git commit -m "feat: merge ponytail+caveman+superpowers lifecycle hooks"
```

---

## Task 6: Unified statusline

Compose the existing per-plugin badges (reuse upstream scripts — don't re-implement) plus a static `[SP]` marker.

**Files:**
- Create: `hooks/scwap-statusline.sh`, `hooks/scwap-statusline.ps1`
- Test: append to `tests/structure.test.mjs`

- [ ] **Step 1: Write the failing test (append)**

```javascript
test('statusline scripts present', () => {
  assert.ok(existsSync(root + 'hooks/scwap-statusline.sh'));
  assert.ok(existsSync(root + 'hooks/scwap-statusline.ps1'));
});
```

(Behavior is verified by the Step 4 smoke test — pure-bash output composition is not worth a brittle cross-platform unit test; ponytail: one runnable check, the smoke test, suffices.)

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/`
Expected: FAIL — statusline files missing.

- [ ] **Step 3: Create the statusline scripts**

`hooks/scwap-statusline.sh`:
```bash
#!/usr/bin/env bash
# scwap unified statusline: [SP] + ponytail badge + caveman badge
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out="\033[38;5;110m[SP]\033[0m"
pony="$(bash "$DIR/ponytail-statusline.sh" 2>/dev/null)"; [ -n "$pony" ] && out="$out  $pony"
cave="$(bash "$DIR/caveman-statusline.sh" 2>/dev/null)"; [ -n "$cave" ] && out="$out  $cave"
printf "%b" "$out"
```

`hooks/scwap-statusline.ps1`:
```powershell
$Dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Esc = [char]27
$out = "${Esc}[38;5;110m[SP]${Esc}[0m"
$pony = & powershell -ExecutionPolicy Bypass -File "$Dir\ponytail-statusline.ps1" 2>$null
if ($pony) { $out = "$out  $pony" }
$cave = & powershell -ExecutionPolicy Bypass -File "$Dir\caveman-statusline.ps1" 2>$null
if ($cave) { $out = "$out  $cave" }
[Console]::Write($out)
```

- [ ] **Step 4: Run test + manual smoke**

Run: `node --test tests/` → Expected: PASS.
Smoke (Git Bash): write a temp flag and confirm composition:
```bash
echo full > /c/Users/Jetsk/.claude/.ponytail-active
bash hooks/scwap-statusline.sh; echo
```
Expected: output contains `[SP]` and `[PONYTAIL]`.

- [ ] **Step 5: Commit**

```bash
git add hooks/scwap-statusline.sh hooks/scwap-statusline.ps1 tests/structure.test.mjs
git commit -m "feat: unified scwap statusline composing all three badges"
```

---

## Task 7: Glue — `scwap-flow` rule + skill

The actual differentiator: ship the three-layer flow so host projects get the orchestration.

**Files:**
- Create: `rules/scwap-flow.md`
- Create: `skills/scwap-flow/SKILL.md`
- Test: append to `tests/structure.test.mjs`

- [ ] **Step 1: Write the failing test (append)**

```javascript
test('scwap-flow rule + skill present with frontmatter', () => {
  assert.ok(existsSync(root + 'rules/scwap-flow.md'));
  const skill = read('skills/scwap-flow/SKILL.md');
  assert.match(skill, /^---/);
  assert.match(skill, /name:\s*scwap-flow/);
  assert.match(skill, /description:\s*\S/);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/`
Expected: FAIL — files missing.

- [ ] **Step 3: Create the rule + skill**

`rules/scwap-flow.md` — the three-layer flow (copy the "Operating mode — three layers" section authored in `~/.claude/CLAUDE.md`: the three layers, default build flow, conflict resolution).

`skills/scwap-flow/SKILL.md`:
```markdown
---
name: scwap-flow
description: Explains how the three scwap layers (Superpowers process, Ponytail build-restraint, Caveman prose) compose. Use when unsure which layer leads or how they interact.
---

# scwap-flow

Three layers, always composed:

1. Process — Superpowers: how the work is approached (brainstorm → plan → TDD → debug → verify → review). Process skills lead.
2. Build restraint — Ponytail: how much gets built (YAGNI ladder, smallest diff).
3. Prose — Caveman: how the agent talks (terse; normal for code/commits/security/legal/client-facing).

Default build flow: brainstorm/plan → build the minimum → prove correct with TDD/verification/review.

Conflict resolution:
- TDD invoked → TDD governs tests; Ponytail still trims production code. No TDD → Ponytail's one-runnable-check default.
- User instructions + host project rules outrank all three layers.
- Never lazy about: understanding the problem, trust-boundary validation, error handling that prevents data loss, security, accessibility, anything explicitly requested.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test tests/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add rules/scwap-flow.md skills/scwap-flow tests/structure.test.mjs
git commit -m "feat: add scwap-flow orchestration rule + skill"
```

---

## Task 8: README + THIRD_PARTY_NOTICES

**Files:**
- Create: `README.md`
- Create: `THIRD_PARTY_NOTICES.md`
- Test: append to `tests/structure.test.mjs`

- [ ] **Step 1: Write the failing test (append)**

```javascript
test('README + notices cover install and all three upstreams', () => {
  const r = read('README.md');
  assert.match(r, /plugin marketplace add/);
  const n = read('THIRD_PARTY_NOTICES.md');
  for (const repo of ['JuliusBrussee/caveman', 'DietrichGebert/ponytail', 'obra/superpowers']) {
    assert.ok(n.includes(repo), 'notices missing ' + repo);
  }
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/`
Expected: FAIL — files missing.

- [ ] **Step 3: Write README.md + THIRD_PARTY_NOTICES.md**

`README.md` covers: what scwap is (three layers), the default build flow, install (`/plugin marketplace add jetskicortez/scwap` then `/plugin install scwap@scwap`), toggles (`/ponytail`, `/caveman`), statusline setup, and a credits section.

`THIRD_PARTY_NOTICES.md` lists each upstream with repo URL, MIT, and pinned SHA:
- `DietrichGebert/ponytail` @ `64adbf9544581e57053a8d84a94e7e4471d40d95`
- `JuliusBrussee/caveman` @ `$CAVE_SHA` (from Task 3)
- `obra/superpowers` @ `$SP_SHA` (from Task 4)

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test tests/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add README.md THIRD_PARTY_NOTICES.md tests/structure.test.mjs
git commit -m "docs: add README + third-party attribution notices"
```

---

## Task 9: Local install verification (registry replication)

Replicate the validated ponytail local-install method so scwap can be smoke-tested before publish.

**Files:**
- Create: `scripts/local-install.sh`
- Test: manual acceptance checklist (restart required — not automatable)

- [ ] **Step 1: Write `scripts/local-install.sh`**

Script does (mirrors the method already used for ponytail):
1. `cp -r` repo → `~/.claude/plugins/marketplaces/scwap`
2. `tar --exclude=.git` repo → `~/.claude/plugins/cache/scwap/scwap/<shortsha>/` + `touch .in_use`
3. Add `scwap` entry to `~/.claude/plugins/known_marketplaces.json` (idempotent: skip if present)
4. Add `scwap@scwap` entry to `~/.claude/plugins/installed_plugins.json` (idempotent)
5. Print the manual step: add `"scwap@scwap": true` to `enabledPlugins` in `settings.json`, run `~/.claude/hooks/update-guard-checksums.sh`, restart. (settings.json is selfprotect-locked — agent cannot edit it; the user runs this.)

- [ ] **Step 2: Validate script syntax**

Run: `bash -n scripts/local-install.sh`
Expected: no output (valid).

- [ ] **Step 3: Run install + enable (manual) + restart**

Run `bash scripts/local-install.sh`, perform the printed manual enable step, restart Claude Code.

- [ ] **Step 4: Acceptance checklist**

- [ ] Statusline shows `[SP] [PONY:FULL] [CAVE:...]`
- [ ] SessionStart injects ponytail + caveman + superpowers context
- [ ] `/ponytail off` then `/caveman ultra` toggle independently; statusline updates
- [ ] A spawned subagent inherits ponytail + caveman
- [ ] `/scwap-flow` skill invokes; superpowers skills (e.g. brainstorming) invoke

- [ ] **Step 5: Commit**

```bash
git add scripts/local-install.sh
git commit -m "chore: add local-install script for registry-replication smoke test"
```

---

## Task 10: `update-vendor.sh` (upstream sync)

**Files:**
- Create: `scripts/update-vendor.sh`
- Test: `bash -n`

- [ ] **Step 1: Write `scripts/update-vendor.sh`**

For each upstream (ponytail, caveman, superpowers): clone to a temp dir at HEAD (or a passed SHA), re-copy the same file sets as Tasks 2–4 into `hooks/`, `skills/`, `commands/`, `licenses/`, print the new SHA, and remind to bump `plugin.json` version + update `THIRD_PARTY_NOTICES.md` SHAs.

- [ ] **Step 2: Validate syntax**

Run: `bash -n scripts/update-vendor.sh`
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add scripts/update-vendor.sh
git commit -m "chore: add update-vendor script for upstream sync"
```

---

## Task 11: Publish (gated — confirm before going public)

Publishing a public repo is outward-facing. **Get explicit user confirmation before `gh repo create --public`.**

- [ ] **Step 1: Final local gate**

```bash
cd /c/Users/Jetsk/Code/scwap
node --test tests/        # all green
git status                # clean
```

- [ ] **Step 2: Confirm with user** — public repo name `jetskicortez/scwap`, description, MIT. Wait for explicit go.

- [ ] **Step 3: Create repo + push feature branch + open PR**

```bash
gh repo create jetskicortez/scwap --public --source . --remote origin --push
gh pr create --title "feat: scwap v0.1.0 — superpowers + ponytail + caveman" \
  --body "See docs/specs and docs/plans. Vendored upstreams (MIT, attributed)."
```
(First push establishes `main`; subsequent changes follow normal PR flow per code-workflow.)

- [ ] **Step 4: Verify** — third-party install works from a clean machine/path:
`/plugin marketplace add jetskicortez/scwap` → `/plugin install scwap@scwap` → restart → acceptance checklist from Task 9.

---

## Self-review notes

- **Spec coverage:** every spec §5–§9 item maps to a task (manifests→T1, vendoring→T2–4, hook merge→T5, statusline→T6, glue→T7, licensing→T8, sync→T10, local test→T9, publish→T11). Spec §4 tree is superseded by the flat-layout note above (documented, with rationale).
- **Cleanup (post-merge):** the temp clones `_ponytail-scan`, `_caveman-vendor`, `_superpowers-vendor` under `Code/` can be removed by the user after Task 4 (anti-delete hook blocks agent `rm`).
- **Known risk:** superpowers `run-hook.cmd`/`session-start` may reference sibling files under its original `hooks/`; if Task 4 Step 4 test or Task 9 acceptance shows a missing-file error, copy the remaining `hooks/*` assets from `_superpowers-vendor/hooks/` (except `hooks.json`, intentionally omitted) and re-test.
