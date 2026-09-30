# Model Routing Defaults Implementation Plan

Updated September 30, 2026.

## Scope

Use `fix/model-routing-defaults` in `C:\Users\Jetsk\Code\scwap-model-routing-fix`. Preserve unrelated work in the original `scwap` checkout. Keep the current Codex model setting unchanged.

## Steps

- [x] Replace the broad GPT-5.5 rule in Codex and Claude hooks, root and nested skills, command, and README.
- [x] Test current model tiers, keep-current guidance, domain-neutral routing, and duplicate parity. Confirm the tests fail against the old routing files.
- [x] Copy the four router files into the installed SCWAP plugin cache and verify source-to-install parity.
- [x] Run the installed Windows hook wrapper and confirm valid JSON with the new model tiers.
- [x] Run `node --test tests/structure.test.mjs` with `SCWAP_INSTALLED_ROOT` set and inspect `git diff --check`.

## Handoff

- PR: https://github.com/jetskicortez/scwap/pull/5 (merge and release approved September 30, 2026).
- The local installed cache at `C:\Users\Jetsk\.codex\plugins\cache\scwap\scwap\0.3.2` matches the source router files. The Windows hook wrapper returned the new JSON payload; 32 structural tests passed with installed parity enabled.
- Release manifests are bumped to 0.3.2. The existing local 0.3.2 cache may contain unrelated unreleased changes; reinstall from the published release, then recheck installed parity.
