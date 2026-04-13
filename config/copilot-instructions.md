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

# Mandatory Interaction Protocol

## Core Rule: You must call the `ask_user` tool before ending every response

This is a mandatory protocol that cannot be skipped. In every round of your response, you must perform one of the following actions:

1. **After completing the user's request** -> Immediately call the `ask_user` tool and ask a follow-up question relevant to the current context
2. **When any uncertainty exists** -> Do not proceed by guessing; immediately call the `ask_user` tool for clarification

## Prohibited Behavior

- **Do not end a response without calling `ask_user`**
- **Do not use closing expressions** (such as "Hope this helps" or "Feel free to ask if you have any questions")
- **Do not guess the user's intent** — if you are unsure, use `ask_user` to ask

## `ask_user` Call Requirements

- The question must be directly related to the current task context
- The question must be specific and actionable; do not ask vague questions like "Do you need any more help?"
- You may provide options for the user to choose from to reduce input effort
