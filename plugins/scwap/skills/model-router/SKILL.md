---
name: model-router
description: Use when choosing, recommending, or switching models for a task.
---

# Model Router

Route by actual task demands, not domain labels. Keep the current active model by default and recommend a switch only when the expected benefit is material. SCWAP can recommend a model; it cannot silently switch the active model.

## Codex

| Use | Model |
|---|---|
| Bounded, reversible mechanical or repetitive cost-sensitive work | `gpt-6-luna` |
| Normal implementation, review, debugging, research, drafting, and professional work | `gpt-6-sol` |
| Hardest end-to-end work where Sol is likely insufficient | `gpt-6-astra` |

Domain labels alone never trigger escalation. A task mentioning money, legal, security, client-facing content, or external systems stays on the current/default model when the work itself is bounded and routine. Route by complexity, consequence, reversibility, and ambiguity. Safety and approval gates remain unchanged regardless of model.

If current model is wrong, say exact switch:

```text
/model gpt-6-luna
/model gpt-6-sol
/model gpt-6-astra
```

For new CLI threads, use `codex -m <model>`. Before switching away from an external-state workflow, summarize current state and pending actions.

## Claude Code

| Use | Model class |
|---|---|
| Reversible mechanical work: search, manifests, lint/tests, small docs, tiny config/path fixes, no-change monitors | fast/cheap |
| Normal implementation and review | default |
| Genuinely complex or high-consequence work | deep |

Domain labels alone never trigger escalation. Route by complexity, consequence, reversibility, and ambiguity.

If current model is wrong, state the exact model switch supported by the active Claude Code install. Do not hard-code stale provider slugs when the installed model list is unknown.
