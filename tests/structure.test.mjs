import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';

// On Windows, import.meta.url pathname yields /C:/Users/... — strip the leading slash before drive letter
const rawRoot = new URL('../', import.meta.url).pathname;
const root = rawRoot.replace(/^\/([A-Za-z]:)/, '$1');

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

test('caveman hooks vendored', () => {
  for (const f of ['caveman-activate.js', 'caveman-config.js',
    'caveman-mode-tracker.js']) {
    assert.ok(existsSync(root + 'hooks/' + f), 'missing hooks/' + f);
  }
});

test('caveman skills vendored', () => {
  for (const s of ['caveman', 'caveman-commit', 'caveman-help',
    'caveman-review', 'caveman-compress']) {
    assert.ok(existsSync(root + 'skills/' + s + '/SKILL.md'), 'missing ' + s);
  }
});

test('caveman license vendored', () => {
  assert.ok(existsSync(root + 'licenses/LICENSE-caveman'));
});

test('superpowers core skills vendored', () => {
  for (const s of ['brainstorming', 'writing-plans', 'test-driven-development',
    'systematic-debugging', 'verification-before-completion',
    'requesting-code-review', 'using-superpowers']) {
    assert.ok(existsSync(root + 'skills/' + s + '/SKILL.md'), 'missing ' + s);
  }
});

test('superpowers session-start bootstrap vendored', () => {
  assert.ok(existsSync(root + 'hooks/run-hook.cmd'), 'missing hooks/run-hook.cmd');
  assert.ok(existsSync(root + 'hooks/session-start'), 'missing hooks/session-start');
});

test('superpowers license vendored', () => {
  assert.ok(existsSync(root + 'licenses/LICENSE-superpowers'));
});

test('scwap-hooks.json valid; every referenced script exists', () => {
  const h = json('hooks/scwap-hooks.json');
  const events = Object.values(h.hooks).flat();
  const cmds = events.flatMap((e) => e.hooks).map((x) => x.command);
  for (const c of cmds) {
    const m = c.match(/hooks\/([A-Za-z0-9._-]+(?:\/[A-Za-z0-9._-]+)?)/);
    if (m) assert.ok(existsSync(root + 'hooks/' + m[1]), 'missing referenced ' + m[1]);
  }
  assert.ok(h.hooks.SessionStart.length >= 1);
  assert.ok(h.hooks.UserPromptSubmit.length >= 1);
  assert.ok(h.hooks.SubagentStart.length >= 1);
});

test('statusline scripts present', () => {
  assert.ok(existsSync(root + 'hooks/scwap-statusline.sh'));
  assert.ok(existsSync(root + 'hooks/scwap-statusline.ps1'));
});

test('plugin.json hooks path resolves to an existing file', () => {
  const p = json('.claude-plugin/plugin.json');
  assert.ok(existsSync(root + p.hooks.replace(/^\.\//, '')), 'plugin.json hooks path does not resolve: ' + p.hooks);
});

test('scwap-flow rule + skill present with frontmatter', () => {
  assert.ok(existsSync(root + 'rules/scwap-flow.md'));
  const skill = read('skills/scwap-flow/SKILL.md');
  assert.match(skill, /^---/);
  assert.match(skill, /name:\s*scwap-flow/);
  assert.match(skill, /description:\s*\S/);
});

test('README + notices cover install and all three upstreams', () => {
  const r = read('README.md');
  assert.match(r, /plugin marketplace add/);
  const n = read('THIRD_PARTY_NOTICES.md');
  for (const repo of ['JuliusBrussee/caveman', 'DietrichGebert/ponytail', 'obra/superpowers']) {
    assert.ok(n.includes(repo), 'notices missing ' + repo);
  }
});
