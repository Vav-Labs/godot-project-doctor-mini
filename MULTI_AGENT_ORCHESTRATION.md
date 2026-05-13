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

## Guardrails

- Do not store API keys or tokens in the repository.
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
