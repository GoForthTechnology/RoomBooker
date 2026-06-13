## Context

Today, `/opsx:propose`, `/opsx:apply`, and `/opsx:archive` operate entirely
against the local working tree on `main`, and the user reviews finished work
via chat after `/opsx:archive` has already committed it. These three skills
are vendored copies of the upstream `openspec` skill package (see
`generatedBy: "1.3.1"` in their frontmatter) under `.claude/skills/` (mirrored
to `.gemini/skills/` per the Agent Config Sync convention).

The user wants a GitHub PR to become the primary review surface: one PR per
OpenSpec change, opened early as a draft, updated incrementally as work
proceeds, and squash-merged once approved.

## Goals / Non-Goals

**Goals:**
- Every OpenSpec change is implemented on its own branch and surfaced as a
  GitHub PR for review.
- The PR is opened early (draft) so the user can watch the proposal/spec
  delta land before code does.
- The agent self-reviews (`/code-review`) before asking the human to review.
- The spec delta stays visible/reviewable for the life of the PR; archiving
  (merging delta into canonical specs) happens as the final step.
- `main` history stays close to one commit per OpenSpec change via squash
  merge.
- A PR Checks CI workflow gives analyze/test signal automatically.

**Non-Goals:**
- Automated/looping polling of PR review comments — feedback handling stays
  manual ("go address PR feedback") for now.
- Changing the release/tagging workflow (`version-driven-cd`) — squash-merge
  commits to `main` do not themselves create release tags.
- Multi-PR splitting of a single OpenSpec change — out of scope for this
  change; can be revisited later if changes prove too large to review.

## Decisions

### 1. Branch naming: `openspec/<change-name>`
Matches the existing `openspec/changes/<name>/` directory naming, making it
obvious which branch corresponds to which change. Created during
`/opsx:propose`, right after `openspec new change` scaffolds the directory.

**Alternative considered**: `feature/<name>` or `claude/<name>` — rejected
because they don't tie back to the OpenSpec change directory as directly.

### 2. Draft PR opened at the end of `/opsx:propose`
Once all `applyRequires` artifacts (proposal, design, specs delta, tasks) are
done, the propose skill:
1. Creates and checks out branch `openspec/<change-name>`.
2. Commits the new `openspec/changes/<change-name>/` directory.
3. Pushes the branch: `git push -u origin openspec/<change-name>`.
4. Opens a **draft PR** via `gh pr create --draft --title "<change-name>"
   --body "<derived from proposal.md>"`.

The PR body is generated from `proposal.md`'s "Why" and "What Changes"
sections so it reads as a normal PR description, not a raw file dump.

**Alternative considered**: open the PR only after implementation
(`/opsx:apply`) completes — rejected per the user's preference for early
visibility, and because the proposal/spec-delta diff is itself useful for the
user to skim before code lands.

### 3. `/opsx:apply` pushes incrementally
After each task (or logical group of tasks) is completed and the task
checkbox updated, the apply skill commits and pushes to the existing branch.
This keeps the draft PR's diff updating live. No change to the *granularity*
of commits beyond what the skill already does — just adds `git push` after
commits that previously stayed local.

### 4. Self-review gate before "Ready for review"
After all tasks are complete, before flipping the PR out of draft, the agent
runs `/code-review` (default effort) against the branch's diff and applies
any high-confidence fixes it finds, pushing a follow-up commit if needed.
Then: `gh pr ready <pr-number>`.

**Alternative considered**: run `/code-review --comment` to post findings as
PR comments for the user to see — rejected for now; the goal is to *reduce*
noise the user has to wade through, not add a visible self-critique trail.
Can revisit later.

### 5. Feedback loop stays manual
The agent does not poll `gh api` for new PR review comments. When the user
says something like "address the PR feedback," the agent runs (for the
relevant PR/branch):
```bash
gh pr view <pr-number> --json reviews,comments
gh api repos/:owner/:repo/pulls/<pr-number>/comments
```
reads unresolved comments, addresses them in code, and pushes follow-up
commits to the same branch (no force-push/rebase — additional commits keep
the PR's review history intact for squash).

### 6. Archive is the final commit, run on the branch before merge
`/opsx:archive` is invoked by the user once they're satisfied with the PR. It
performs its existing behavior (merge delta specs into
`openspec/specs/<capability>/spec.md`, move
`openspec/changes/<name>/` to `openspec/changes/archive/YYYY-MM-DD-<name>/`),
commits, and pushes to the branch as the last commit.

This keeps the delta spec — a small, focused diff — visible as "the spec
change for this PR" throughout review, rather than asking the reviewer to
diff the full merged `spec.md`.

**Risk**: if review feedback after archiving requires further spec changes,
the agent edits the *archived* delta location
(`openspec/changes/archive/YYYY-MM-DD-<name>/specs/...`) and re-runs the
merge into `openspec/specs/`. This is a minor edge case; documented in tasks
rather than fully engineered for.

### 7. Squash merge to `main`
Once the user approves, they (or the agent, if asked) run:
```bash
gh pr merge <pr-number> --squash --delete-branch
```
The squash commit message uses the PR title/body (i.e., derived from
`proposal.md`), so `main`'s `git log` reads like it does today — one
descriptive commit per change — while the PR retains the full incremental
history on GitHub.

**Note**: Per global git safety rules, the agent does not push to `main` or
merge PRs without being asked. Document this explicitly in the workflow
section of CLAUDE.md/GEMINI.md.

### 8. PR Checks CI workflow
New `.github/workflows/pr-checks.yml`, triggered on
`pull_request: [opened, synchronize, reopened]` targeting `main`. Two jobs
(or one job, two steps) running:
```bash
(cd packages/roombooker_core && flutter test)
(cd packages/roombooker_portal && flutter test)
flutter analyze
```
Mirrors the commands already documented in CLAUDE.md's "Running Tests" /
"Linting" sections — no new tooling, just wiring them to run on PRs. Kept
deliberately separate from `android-release.yml` (tag-triggered release
pipeline) and `firebase-hosting-merge.yml` (merge-triggered deploy).

### 9. Skill updates are additive edits to vendored skills
`.claude/skills/openspec-propose/SKILL.md`,
`.claude/skills/openspec-apply-change/SKILL.md`, and
`.claude/skills/openspec-archive-change/SKILL.md` (and their `.gemini/`
mirrors) get new steps inserted for branch/PR management as described above.

**Alternative considered**: leave the vendored skills untouched and add a
*new* wrapper skill (e.g. `pr-workflow`) that orchestrates branch/PR steps
around calls to the existing skills — rejected because it adds an extra
invocation step for the user and the existing skills already have the right
"loop until done" structure; editing in place is simpler. The trade-off
(skill updates from `openspec` CLI upgrades may need to be re-merged) is
accepted and noted as a risk below.

## Risks / Trade-offs

- **Vendored skill drift**: editing `.claude/skills/openspec-*` directly
  means a future `openspec` CLI/package upgrade that regenerates these files
  could overwrite our PR-workflow additions. → Mitigation: keep the added
  steps clearly delimited/commented so a future merge is easy, and note this
  in tasks.md as a known maintenance cost.
- **`gh` auth/availability**: skills now depend on `gh` CLI being
  authenticated with push/PR permissions. → Mitigation: document the
  prerequisite in CLAUDE.md; skills should fail gracefully (clear error
  message) if `gh` isn't available, rather than silently skipping PR steps.
- **Draft PR opened before any code exists**: a PR with only doc changes
  might look "empty" to GitHub's UI / confuse external integrations. →
  Acceptable; this is the intended early-visibility behavior.
- **Archive-then-feedback edge case** (see Decision 6): if the user requests
  spec changes after archiving, the workflow is slightly more manual. →
  Acceptable for now; revisit if it proves common.
- **Branch cleanup**: if a change is abandoned, its branch and draft PR
  linger. → Mitigation: document in CLAUDE.md that abandoning a change means
  closing the PR and deleting the branch (`gh pr close --delete-branch`).

## Migration Plan

No data/runtime migration. Rollout is:
1. Add `pr-checks.yml` workflow (independently useful, low risk).
2. Update the three OpenSpec skills (propose/apply/archive) with the new
   branch/PR steps, mirrored to `.gemini/skills/`.
3. Update `CLAUDE.md`/`GEMINI.md` "Development Workflow" section.
4. This change itself (`adopt-pr-review-workflow`) is the first change to be
   run through the new flow where possible — i.e., once the skills are
   updated, use them to open/manage this change's own PR going forward
   (bootstrapping note in tasks.md).

Rollback is trivial: revert the skill/workflow/doc edits; no other state to
unwind.

## Open Questions

- Should `/code-review`'s findings ever be posted as PR comments
  (`--comment`) instead of silently auto-fixed, for transparency? Deferred —
  revisit if the user wants visibility into what the self-review caught.
- Should there be a convention for *very small* changes (e.g., a one-line
  doc fix) to skip the draft-PR-early step and just open a normal PR after
  the fact? Deferred — out of scope; can be handled case-by-case by asking
  the user.
