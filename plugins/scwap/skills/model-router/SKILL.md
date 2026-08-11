---
name: model-router
description: Use when choosing, recommending, or switching Codex models for a task, especially Spark versus full-model routing.
---

# Model Router

Route by risk, not vibes. SCWAP can recommend a model; it cannot silently switch the active model.

## Codex

| Use | Model |
|---|---|
| Reversible mechanical work: search, manifests, lint/tests, small docs, tiny config/path fixes, no-change monitors | `gpt-5.3-codex-spark` |
| Routine work when Spark is unavailable | `gpt-5.4-mini` |
| Architecture, non-trivial code, security, money, legal, client-facing text, external sends, deploys, merge/publish checks, ambiguous judgment | `gpt-5.5` |

If current model is wrong, say exact switch:

```text
/model gpt-5.3-codex-spark
/model gpt-5.4-mini
/model gpt-5.5
```

For new CLI threads, use `codex -m <model>`. Before switching away from an external-state workflow, summarize current state and pending actions.

## Claude Code

| Use | Model class |
|---|---|
| Reversible mechanical work: search, manifests, lint/tests, small docs, tiny config/path fixes, no-change monitors | fast/cheap |
| Normal implementation and review | default |
| Architecture, non-trivial code, security, money, legal, client-facing text, external sends, deploys, merge/publish checks, ambiguous judgment | deep |

If current model is wrong, state the exact model switch supported by the active Claude Code install. Do not hard-code stale provider slugs when the installed model list is unknown.
