## ADDED Requirements

### Requirement: Branch and Draft PR per Change
Each OpenSpec change SHALL be developed on its own dedicated branch, with a
draft GitHub Pull Request opened once the change's proposal, design, spec
deltas, and tasks artifacts are complete.

#### Scenario: Branch created for new change
- **WHEN** all `applyRequires` artifacts for a new OpenSpec change are
  complete
- **THEN** a branch named `openspec/<change-name>` SHALL be created from
  `main`, the change's `openspec/changes/<change-name>/` directory SHALL be
  committed to it, and the branch SHALL be pushed to the remote.

#### Scenario: Draft PR opened with proposal-derived description
- **WHEN** the branch for a change has been pushed
- **THEN** a draft Pull Request SHALL be opened targeting `main`, with a
  title based on the change name and a description derived from
  `proposal.md`'s "Why" and "What Changes" sections.

### Requirement: Incremental Implementation Commits
Implementation work for a change SHALL be committed and pushed incrementally
to the change's branch as tasks are completed, so the draft PR's diff
reflects progress.

#### Scenario: Task completion pushes progress
- **WHEN** one or more tasks in `tasks.md` are completed and marked `[x]`
- **THEN** the corresponding code and test changes, along with the updated
  `tasks.md`, SHALL be committed and pushed to the change's branch.

### Requirement: Self-Review Before Ready for Review
Before a change's PR is marked ready for human review, a self-review of the
PR's diff SHALL be performed and any resulting high-confidence fixes applied.

#### Scenario: Self-review runs after all tasks complete
- **WHEN** all tasks in `tasks.md` are marked complete
- **THEN** a code review of the branch's diff against `main` SHALL be
  performed, high-confidence findings SHALL be fixed and pushed, and the PR
  SHALL then be transitioned from draft to "Ready for review".

### Requirement: Manual PR Feedback Handling
PR review feedback SHALL be addressed only when explicitly requested by the
user, by reading PR review comments and pushing follow-up commits to the
same branch.

#### Scenario: User requests feedback be addressed
- **WHEN** the user asks for PR feedback on a change to be addressed
- **THEN** unresolved review comments on that change's PR SHALL be read,
  addressed via code changes, and pushed as additional commits to the
  change's existing branch without rewriting prior commit history.

### Requirement: Archive as Final Pre-Merge Step
Merging a change's spec deltas into the canonical specs and archiving the
change directory SHALL occur as the final commit on the change's branch,
after the user has approved the PR and before it is merged.

#### Scenario: Archive performed after approval
- **WHEN** the user approves a change's PR and requests it be archived
- **THEN** the change's spec deltas SHALL be merged into
  `openspec/specs/<capability>/spec.md`, the change directory SHALL be moved
  to `openspec/changes/archive/YYYY-MM-DD-<change-name>/`, and this SHALL be
  committed and pushed to the branch as its final commit prior to merge.

### Requirement: Squash Merge to Main
A change's PR SHALL be merged into `main` using a squash merge, preserving
the PR title/description as the resulting commit message, and SHALL only be
merged when the user requests it.

#### Scenario: Approved PR is squash-merged
- **WHEN** the user requests a change's approved PR be merged
- **THEN** the PR SHALL be squash-merged into `main` with its branch deleted,
  resulting in a single commit on `main` whose message is derived from the
  PR title/description.

### Requirement: PR Checks CI Workflow
A GitHub Actions workflow SHALL run static analysis and tests for
`roombooker_core` and `roombooker_portal` on every pull request targeting
`main`. The static analysis step SHALL block the workflow on failure (no
`continue-on-error`).

#### Scenario: PR triggers checks
- **WHEN** a pull request targeting `main` is opened, synchronized, or
  reopened
- **THEN** a CI workflow SHALL run `flutter analyze` and `flutter test` for
  both `roombooker_core` and `roombooker_portal`, reporting pass/fail status
  on the PR.

#### Scenario: Analyze step fails
- **WHEN** `flutter analyze` reports any issue during a PR's CI run
- **THEN** the Analyze step SHALL fail the workflow run, blocking the PR
  check rather than continuing past the failure.
