# Model Routing Defaults Design

Updated September 30, 2026.

## Goal

Stop SCWAP from recommending GPT-5.5 for most work and keep routing aligned with models available on this Codex host.

## Design

- Keep the active model by default. Recommend a switch only when the benefit is material.
- Use `gpt-6-luna` for bounded mechanical or repetitive cost-sensitive work.
- Use `gpt-6-sol` for normal implementation, review, debugging, research, drafting, and professional work.
- Use `gpt-6-astra` only for the hardest end-to-end work where Sol is likely insufficient.
- Route by complexity, consequence, reversibility, and ambiguity, not domain labels such as money, legal, security, or client-facing.
- Keep routing advisory. It never switches models automatically or changes safety gates.

## Verification

Structural tests check the tiers, default-stay rule, and root/nested copies. With `SCWAP_INSTALLED_ROOT` set, the same tests compare the installed hook, skill, and command with source. The Windows hook wrapper must return valid JSON with the new routing text.
