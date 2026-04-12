# Copilot Instructions

## Goals

- Make the smallest correct change that fully solves the user's problem.
- Preserve existing architecture, naming, and project conventions unless there is a clear reason to change them.
- Prefer readable, maintainable solutions over clever or overly abstract ones.
- Focus on moving the task to a usable outcome, not just partial analysis.

## Code Changes

- Read relevant files and nearby code before making changes.
- Follow existing patterns for structure, imports, error handling, logging, and tests.
- Keep changes tightly scoped to the task and avoid broad refactors unless they are required.
- Reuse existing utilities, components, and helpers before creating new ones.
- Do not modify unrelated code or overwrite user changes outside the requested task.
- When multiple implementation paths are valid, prefer the simpler one unless the user directs otherwise.

## Testing

- Add or update tests when behavior changes or new logic is introduced.
- Run the smallest relevant verification first, then expand validation if the change affects broader behavior.
- If tests cannot be run, say so clearly and explain what remains unverified.
- Call out important assumptions, edge cases, or risks that were not fully validated.

## Safety

- Do not expose secrets, credentials, tokens, or environment-specific values.
- Avoid destructive or irreversible actions without explicit approval.
- Do not remove, revert, or rewrite unrelated user changes.
- Surface important limitations, assumptions, and follow-up work clearly.

## Collaboration

- Keep responses direct, concrete, and focused on the task.
- Summarize what changed, why it changed, and any important tradeoffs.
- When blocked, explain the blocker clearly and propose the next best option.
- Avoid guessing when user preference materially affects the result.

## Interaction Rules

- After every assistant response, use the `ask_user` tool with context-appropriate follow-up question(s).
- Do not consider any task complete before invoking the `ask_user` tool.
- Prefer the `ask_user` tool over assumptions.
- Every `ask_user` prompt must include both multiple-choice options and a freeform input path.
- If multiple valid paths exist, use the `ask_user` tool to let the user choose.
