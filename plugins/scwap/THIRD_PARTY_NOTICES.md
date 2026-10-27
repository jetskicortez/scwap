# Third-Party Notices

scwap vendors four open-source projects. ponytail and superpowers are distributed under the MIT License; caveman (since 3.0.0) and Impeccable are distributed under the Apache License 2.0. Each license is preserved verbatim in the `licenses/` directory of this repository.

---

## caveman

- **Project:** caveman
- **Repository:** github.com/JuliusBrussee/caveman
- **License:** Apache-2.0 (MIT before 3.0.0)
- **Version:** v4.0.1
- **Pinned commit:** `d262ab3882952a59312ff3537cd86d894523c5ab`
- **Vendored:** `src/hooks/*.js` + statusline scripts, skills caveman/ultracave/megacave/caveman-commit/caveman-review/caveman-help/caveman-compress, matching commands
- **License file:** `licenses/LICENSE-caveman` (Apache-2.0 NOTICE preserved as `licenses/NOTICE-caveman`)

---

## ponytail

- **Project:** ponytail
- **Repository:** github.com/DietrichGebert/ponytail
- **License:** MIT
- **Version:** v5.3.2
- **Pinned commit:** `16352ac229eb08a9598dcae48fe9f2b342567d86`
- **Vendored:** core hooks, skills, commands. The optional task band (`hooks/band/`, `hooks/claude-band.json`) is not bundled.
- **License file:** `licenses/LICENSE-ponytail`

---

## superpowers

- **Project:** superpowers
- **Repository:** github.com/obra/superpowers
- **License:** MIT
- **Version:** v7.0.1
- **Pinned commit:** `2ce8aa15d05bd57213e6f746f953aafb7ded7a8b`
- **License file:** `licenses/LICENSE-superpowers`

---

## impeccable

- **Project:** impeccable
- **Repository:** github.com/pbakaus/impeccable
- **License:** Apache-2.0
- **Version:** 4.8.0 (skill payload from `.claude/skills/impeccable`, agents from `.claude/agents`; engine binary 0.1.18 is fetched by the launcher, not vendored)
- **Pinned commit:** `414603bf14c7a344edb466bb1f85690c77ce8b7d` (tag cli-v4.8.0)
- **License file:** `licenses/LICENSE-impeccable` (NOTICE preserved as `licenses/NOTICE-impeccable`)

---

scwap itself is MIT licensed. See `LICENSE` in the repository root.
