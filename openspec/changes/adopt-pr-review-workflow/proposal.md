## Why

Today, OpenSpec changes are implemented and committed straight to `main` by
the AI agent, with the user reviewing the work after the fact in chat. As the
project grows, the user wants a clearer, async review surface: GitHub Pull
Requests, where diffs, spec deltas, and CI results are visible together and
feedback can be left as PR comments.

## What Changes

- Each OpenSpec change gets its own branch (`openspec/<change-name>`) and an
  early **draft PR**, opened as part of `/opsx:propose` once the proposal,
  design, spec deltas, and tasks artifacts exist. The initial PR diff is just
  these OpenSpec documents, with the PR description derived from
  `proposal.md`.
- `/opsx:apply` commits implementation work (code + tests) incrementally to
  that branch and pushes to the remote as tasks complete.
- Before marking the PR ready for review, the agent runs `/code-review` on
  its own changes and fixes findings.
- The agent then marks the PR "Ready for review" for the user to review on
  GitHub.
- Feedback loop is manual for now: the user reviews on GitHub and tells the
  agent (in chat) to go address PR feedback. The agent reads PR review
  comments via `gh`, addresses them, and pushes follow-up commits to the same
  branch.
- `/opsx:archive` (merging spec deltas into `openspec/specs/` and moving the
  change folder to `openspec/changes/archive/`) becomes the LAST commit on
  the branch, run once the user approves — keeping the spec delta visible as
  its own reviewable diff for the life of the PR instead of a diff against
  the already-merged spec.
- The PR is squash-merged into `main`, so `main`'s history stays
  approximately one commit per OpenSpec change, with the squashed commit
  message derived from the PR description (i.e. `proposal.md`).
- A new lightweight **PR Checks** GitHub Actions workflow runs `flutter
  analyze` plus `flutter test` for both `roombooker_core` and
  `roombooker_portal` on pull request open/sync, giving the user a pass/fail
  signal before they start reviewing.
- `CLAUDE.md` and `GEMINI.md` (per the existing Agent Config Sync section)
  are updated to document this as the new standard "Development Workflow."

## Capabilities

### New Capabilities
- `pr-review-workflow`: Defines the branch/PR lifecycle for OpenSpec changes
  — branch naming, draft-PR creation timing, self-review-before-ready,
  feedback handling, archive timing, and merge strategy.

### Modified Capabilities
(none — no existing spec's runtime behavior changes; `version-driven-cd`
covers release tagging and is unaffected since PR merges to `main` don't by
themselves create version tags)

## Impact

- **Process/tooling only** — no application runtime code changes.
- `CLAUDE.md`, `GEMINI.md`: "Development Workflow" section rewritten to
  describe the branch/PR lifecycle.
- `.claude/skills/` (and mirrored `.gemini/skills/`) for
  `openspec-propose`, `openspec-apply`, and `openspec-archive` (or their
  `opsx:*` equivalents): updated to create branches, open/update the draft
  PR, run `/code-review`, and perform the squash-merge handoff.
- New GitHub Actions workflow file, e.g. `.github/workflows/pr-checks.yml`.
- Requires `gh` CLI authenticated with permission to create branches, push,
  open PRs, and read PR review comments on this repo.
