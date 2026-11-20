# Project instructions
- Preserve the original lab documents and harness history. Do not rewrite or delete working code without a scoped task and a clear reason.
- Read the assigned task and relevant project sources before changing files:
  - Product requirements: `PRD.md` at the repository root (there is no `docs/PRD.md`).
  - Technical draft: `game.contract.json` at the repository root. It is PRD-derived and is not the official Test Contract.
  - Architecture and task plan: `docs/ARCHITECTURE.md` and `docs/TASKS.md`.
  - Read the official Test Contract v1.0 when it is supplied. It is not currently present in this repository.
- Authority is scoped: the PRD defines product scope and required features; the approved game contract defines technical gameplay behavior; the official Test Contract overrides the draft for its specified protocol and graded behavior. If applicable sources conflict, stop affected work, document the conflict, and ask the Product Owner. Do not invent a resolution or edit the PRD/contract without authorization.
- Godot 4 + GDScript is the planned game stack. Keep gameplay rules in `src/core` independent of `Node3D`, UI, rendering, audio, and scene-tree state. Scenes and actors are adapters, not a second source of gameplay state.
- The repository preserves its CP0 web/Vite scaffold and now has a minimal Godot project at `godot/` (project name `game_AAA`); gameplay is not implemented yet. Treat `src/core/smoke.js` and `headless:smoke` as environment probes, not gameplay or the grading contract. Do not overwrite the scaffold.
- Do not implement the official headless protocol until its source specifies the command, input/output schema, and error/exit behavior. While it is unavailable, work only on tasks explicitly unblocked in `docs/TASKS.md`; keep provisional values isolated and labeled.
- Roles:
  - **Codex — Orchestrator & Reviewer:** select the next dependency-ready task, state exact file ownership and acceptance criteria, inspect the diff and test evidence, and reject scope creep or incomplete work. The reviewer must be a different agent from the implementer.
  - **Claude Code — Developer:** implement one assigned task per session, read its sources, edit only its authorized files, add/update focused tests, run them, and report results and remaining issues. Ask before expanding scope or changing a shared interface.
- Keep each task small and independently reviewable. Never have agents edit the same file concurrently. Follow the dependency and parallel-work rules in `docs/TASKS.md`.
- Task workflow: `TODO → IN_PROGRESS → TESTING → REVIEW → DONE`. If a test or review fails, return to `IN_PROGRESS`; use `BLOCKED` when an external decision or input is required. Do not merge before tests and independent review pass.
- Every task report must include task ID, work completed, changed files, commands/tests and actual results, evidence location, unresolved issues, and commit hash if one exists.
- DONE requires all task acceptance criteria, relevant tests passing, no unresolved critical defect or contract violation, real verifiable evidence, and approval from an independent reviewer. Never claim a test passed unless it was run.
- Define acceptance criteria and verification before implementation. Re-run affected checks after changes. Keep assumptions, AI usage, and limitations in `docs/notes`; never invent token counts or evidence.
- Git: use a task-specific branch when practical; create a clear task commit; do not commit another task's changes; merge only after review approval. Protect `main`. Create tag `phase-1` only after the entire phase has been evaluated and accepted.
- Never commit `node_modules`, `dist`, `.env`, credentials, or other secrets. Do not use destructive Git commands or change machine-wide execution policy.
- Current CP0 commands (not the future Godot game commands): `npm run dev`, `npm run verify`, and `npm run build`. On Windows use `npm.cmd` or `.\lab.cmd run verify` / `.\lab.cmd run dev`. If PowerShell blocks `activate.ps1`, use `lab.cmd`; do not change system execution policy. Add Godot commands only after the Godot project and its verified workflow exist.


## Cập nhật (cuối Phase 1)
- Test Contract chính thức có ở `contract/TEST_CONTRACT_v1.0.md`; `game.contract.json` ở gốc đã theo schema đó.
- Giao thức headless: `scripts/headless.sh --seed N --night 1 [--scenario F] [--inputs F] --ticks N --out F`. Test: `GODOT --headless --path godot --script res://tests/run_core_tests.gd`; kịch bản: `scripts/run_scenarios.sh`; tất định: `scripts/verify_determinism.sh`.
- Không chạy `--import`/`--editor` trên máy dev (treo); core tham chiếu file mới bằng `preload`, không dựa `class_name`.
- Chọn model subagent theo độ khó (haiku/sonnet/opus) để tiết kiệm token.
