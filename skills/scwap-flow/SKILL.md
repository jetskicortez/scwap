---
name: scwap-flow
description: Explains how SCWAP's process, build-restraint, prose, and frontend craft layers compose and which one leads. Use when unsure how the layers interact or which takes precedence.
---

# scwap-flow

Three core layers plus frontend craft, always composed:

1. Process - Superpowers: how the work is approached (brainstorm -> plan -> TDD -> debug -> verify -> review). Process skills lead.
2. Build restraint - Ponytail: how much gets built (YAGNI ladder, smallest diff, deletion over addition).
3. Prose - Caveman: how the agent talks (terse; normal for code/commits/security/legal/client-facing).
4. Frontend craft - Impeccable: how UI quality is protected (product/design context, polish, critique, live tooling, post-edit detector).

Default build flow: brainstorm/plan -> decide what -> build the minimum -> polish UI when relevant -> prove correct with TDD/verification/review.

Conflict resolution:
- TDD invoked -> TDD governs tests; Ponytail still trims production code. No TDD -> Ponytail's one-runnable-check default.
- Impeccable governs frontend/design craft; Ponytail still trims unnecessary implementation scope.
- User instructions + host project rules outrank all bundled layers.
- Never lazy about: understanding the problem, trust-boundary validation, error handling that prevents data loss, security, accessibility, anything explicitly requested.

Toggle independently: `/ponytail lite|full|ultra|off`, `/caveman lite|full|ultra|off`.
