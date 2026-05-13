# Multi-Agent Orchestration Plan

Date: 2026-05-13
Project: Godot Project Doctor Mini

## Goal

Use a small, clear multi-agent workflow for Godot development without Cline.

The setup should combine:

- GitHub Copilot for in-editor implementation.
- ChatGPT/Codex for planning, review, and larger reasoning tasks.
- MCP for shared tool/context access where useful.
- GitHub for source control, issues, pull requests, and automation.

## Agents And Roles

### 1. Lead Coding Agent: GitHub Copilot

Use Copilot inside VS Code as the main implementation agent.

Best for:

- Editing GDScript, Markdown, JSON, and project config files.
- Small-to-medium refactors.
- Explaining local code.
- Generating focused tests or manual verification steps.
- Working with GitHub issues and PRs.
- Using repository instructions from `.github/copilot-instructions.md`.

Default rule:

Copilot is the only agent that should directly change project files during normal development unless you intentionally switch workflows.

### 2. Planning And Review Agent: ChatGPT / Codex

Use ChatGPT or Codex for higher-level work before or after implementation.

Best for:

- Architecture options.
- Feature decomposition.
- Risk review.
- API and UX wording.
- Test strategy.
- Release notes.
- Reviewing scanner heuristics and false-positive risk.

Default rule:

ChatGPT/Codex should produce plans, reviews, or patches that Copilot applies in VS Code after checking local context.

### 3. Context And Tool Layer: MCP

Use MCP as the shared tool layer, not as a separate decision-maker.

Recommended initial MCP servers:

- Filesystem: restricted to this project folder.
- Git: local status, diff, log, and blame.
- GitHub: issues, pull requests, repository metadata.

Optional later MCP servers:

- Playwright: only if the project gets a web export, dashboard, docs site, or browser UI.
- Docker/container tools: only if export or build automation needs containers.

Default rule:

MCP tools should expose only the minimum context needed for the current task. Avoid broad filesystem access.

### 4. Source Of Truth: GitHub

Use GitHub as the durable project coordination layer.

Best for:

- Issues for feature requests and bugs.
- Pull requests for reviewable change sets.
- GitHub Actions later for validation/export checks.
- Releases once the plugin becomes reusable.

Default rule:

Local commits should stay small and descriptive. Push only when a remote exists and the branch is ready to share.

## Workflow Modes

### Mode A: Fast Local Edit

Use for small implementation tasks.

1. Copilot reads local files.
2. Copilot edits the minimal files needed.
3. Run Godot headless validation.
4. Commit locally.

Example tasks:

- Add a scanner check.
- Fix a GDScript error.
- Update README.
- Tune VS Code settings.

### Mode B: Plan First

Use for unclear or larger tasks.

1. ChatGPT/Codex drafts a feature plan.
2. Copilot adapts the plan to the repository.
3. Copilot implements one small phase.
4. Validate in Godot and commit.

Example tasks:

- Redesign report format.
- Add plugin settings.
- Prepare Asset Library packaging.
- Decide C# scanner boundaries.

### Mode C: Review Loop

Use before merging or publishing.

1. Copilot summarizes the diff.
2. ChatGPT/Codex reviews the design and risks.
3. Copilot fixes accepted findings.
4. Run validation.
5. Commit and push.

Example tasks:

- Before creating a pull request.
- Before tagging a release.
- Before submitting to Godot Asset Library.

### Mode D: MCP-Assisted Investigation

Use when the agent needs wider context.

1. Enable only the MCP servers required for the task.
2. Query local Git/GitHub/filesystem context.
3. Keep edits in Copilot/VS Code.
4. Disable or ignore unneeded tools after the task.

Example tasks:

- Compare current behavior with a GitHub issue.
- Inspect commit history around a scanner bug.
- Gather PR review context.

## Task Routing

| Task | Primary Agent | Support |
| --- | --- | --- |
| GDScript implementation | Copilot | MCP filesystem/Git |
| Godot plugin UI | Copilot | ChatGPT for UX review |
| Scanner heuristic design | ChatGPT/Codex | Copilot for implementation |
| Bug diagnosis | Copilot | MCP Git/filesystem |
| PR description | Copilot | GitHub MCP |
| Architecture review | ChatGPT/Codex | Copilot summary |
| Release checklist | ChatGPT/Codex | GitHub MCP |
| CI/export automation | Copilot | ChatGPT/Codex planning |

## Definition Of Done

A task is done only when the implementation, validation, and documentation all match the size of the change.

For code changes:

- The project opens in Godot without new editor errors.
- `Godot: Validate Project Headless` passes, or the reason it cannot run is documented.
- The plugin still loads from `addons/project_doctor_mini/plugin.cfg`.
- New findings follow the shared finding shape: `id`, `severity`, `title`, `path`, `message`, `recommendation`.
- Generated reports remain ignored by Git.
- User-facing behavior is reflected in README or planning docs when it changes.

For documentation-only changes:

- The updated document has one clear purpose.
- Links point to existing repository files.
- The content matches the current project state, not a future assumption.
- No secrets, local tokens, or private credentials are included.

For AI/MCP setup changes:

- The affected agent or tool has a clear owner and role.
- Any required authentication is stored outside the repository.
- MCP access is scoped to the minimum useful context.
- The setup is recorded in the relevant setup document, not only in chat history.

## Validation Command

Preferred validation:

```text
Godot: Validate Project Headless
```

Preferred scanner validation:

```text
Godot: Scan Project Headless
```

Equivalent command-line validation should be documented in the repository once the local Godot executable path is known.

Example shape:

```text
godot --headless --path . --quit
```

Scanner command shape:

```text
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_scan.gd
```

The exact command may differ by OS and Godot installation path. For this workspace, VS Code tasks read the local Godot 4.6.2 Mono executable from `godotTools.editorPath.godot4`.

## Generated Output Policy

Generated scanner reports are local diagnostic artifacts.

Rules:

- Reports should not be committed by default.
- `.gitignore` should exclude generated report files and report folders.
- Example reports may be committed only when intentionally used as fixtures, documentation samples, or release assets.
- Report filenames should be deterministic enough for debugging but not overwrite previous runs unexpectedly.
- Reports must not include secrets, absolute machine paths, or private environment data.

## Branch And Commit Policy

Use small, reviewable commits. Prefer one completed task per commit.

Branch policy:

- `master` is acceptable for local MVP work before a remote exists.
- After a GitHub remote is created, use short feature branches for meaningful changes.
- Branch names should be lowercase and action-oriented, such as `feature/scanner-checks`, `fix/plugin-load`, or `docs/ai-workflow`.
- Avoid mixing setup, feature work, and cleanup in the same branch when the changes can be separated naturally.

Commit policy:

- Commit after a coherent change validates locally.
- Use imperative commit messages, such as `Add scanner report writers`.
- Keep generated files out of commits unless they are intentional fixtures.
- Do not commit `.godot/`, exported builds, diagnostic reports, API keys, tokens, or machine-local secrets.
- If a remote exists, push only when the branch is ready to share or back up.

Suggested commit message types:

- `Add ...` for new behavior or files.
- `Fix ...` for bugs.
- `Update ...` for docs, config, or existing behavior.
- `Refactor ...` for structure-preserving changes.
- `Document ...` for documentation-only commits.

## Required Repository Instruction Files

These files keep agents aligned and reduce repeated setup explanation.

Required now:

- `.github/copilot-instructions.md`: repository-specific instructions for Copilot and compatible coding agents.
- `README.md`: project entrypoint, run/debug notes, and current MVP status.
- `docs/MULTI_AGENT_ORCHESTRATION.md`: agent roles, workflow modes, policies, and guardrails.
- `docs/GODOT_PROJECT_DOCTOR_MINI.md`: product/MVP specification for the plugin.
- `docs/GODOT_VSCODE_AI_MCP_SETUP_PLAN.md`: machine and workspace setup notes.

Recommended when the project grows:

- `CONTRIBUTING.md`: contribution flow, local validation, issue/PR expectations.
- `CHANGELOG.md`: user-facing changes by version.
- `docs/scanner-checks.md`: detailed behavior and false-positive notes for each scanner check.
- `.github/pull_request_template.md`: consistent PR summaries and validation checklists.
- `.github/ISSUE_TEMPLATE/`: structured bug reports and feature requests.

Instruction file rules:

- Keep instructions short enough that agents can actually follow them.
- Put durable project rules in `.github/copilot-instructions.md`.
- Put task plans and design notes in docs, not in agent instruction files.
- Update instruction files when the workflow changes, especially around tools, validation, and file ownership.
- Do not duplicate secrets, tokens, or local-only authentication steps.

## Scanner Heuristic Policy

Scanner checks should be useful, explainable, and conservative. The goal is to surface likely issues without pretending every finding is certain.

Heuristic rules:

- Prefer `warning` or `info` when a check may produce false positives.
- Use `error` only for clearly broken references or missing required files.
- Every finding must include a practical recommendation.
- Dynamic Godot behavior, such as runtime `load()` paths, should be described as a detection limitation when relevant.
- Checks must not delete, move, rewrite, import, or reconfigure project files.
- Checks should scan `res://` paths and avoid machine-specific absolute paths.
- Thresholds should start simple and become configurable only after they prove useful.

Severity guidance:

| Severity | Use When |
| --- | --- |
| `error` | A referenced file or required project asset is missing. |
| `warning` | The project may run, but export readiness, performance, or maintenance could suffer. |
| `info` | The finding is a hygiene hint or needs manual confirmation. |

Adding a new check requires:

1. A stable `id`.
2. A clear severity choice.
3. A short title and message.
4. A recommendation that tells the user what to do next.
5. At least one manual test case in the planning docs or PR notes.
6. A note if the check can miss dynamic behavior or report false positives.

## Guardrails

- Do not store API keys or tokens in the repository.
- ChatGPT/Codex should not be treated as the direct file-editing agent in the normal workflow. It may produce plans, reviews, snippets, or patch suggestions, but Copilot applies changes after inspecting local context.
- Keep project-level settings portable where possible.
- Keep MCP filesystem access restricted to the workspace.
- Prefer one active editing agent at a time.
- Keep commits small enough to review.
- Validate Godot changes with the headless task when possible.
- Avoid adding external dependencies during the MVP.

## Recommended Daily Loop

1. Create or choose one small task.
2. Ask Copilot to inspect the relevant files.
3. Implement the smallest useful change.
4. Run `Godot: Validate Project Headless`.
5. Commit locally.
6. Use ChatGPT/Codex for review only when the task has design risk.
7. Push when a remote exists and the change is ready.

## Current Decision

Cline is intentionally not part of this setup.

The preferred stack is:

```text
VS Code + GitHub Copilot + ChatGPT/Codex + MCP + GitHub
```
