## 1. PR Checks CI Workflow

- [x] 1.1 Add `.github/workflows/pr-checks.yml` triggered on
      `pull_request` (opened, synchronize, reopened) targeting `main`,
      running `flutter test` for `roombooker_core` and
      `roombooker_portal`, and `flutter analyze` for the workspace.

## 2. Update `openspec-propose` Skill

- [x] 2.1 In `.claude/skills/openspec-propose/SKILL.md`, add steps (after all
      `applyRequires` artifacts are done) to: create branch
      `openspec/<change-name>`, commit the new change directory, push the
      branch, and open a draft PR via `gh pr create --draft` with a
      description derived from `proposal.md`.
- [x] 2.2 Mirror the same changes to
      `.gemini/skills/openspec-propose/SKILL.md` (or equivalent).

## 3. Update `openspec-apply-change` Skill

- [x] 3.1 In `.claude/skills/openspec-apply-change/SKILL.md`, add a step
      after each task (or logical group of tasks) is completed to commit and
      push progress to the change's branch.
- [x] 3.2 Add a step for when all tasks are complete: run `/code-review`
      against the branch diff, apply high-confidence fixes, push, then mark
      the PR ready via `gh pr ready`.
- [x] 3.3 Mirror the same changes to
      `.gemini/skills/openspec-apply-change/SKILL.md` (or equivalent).

## 4. Update `openspec-archive-change` Skill

- [x] 4.1 In `.claude/skills/openspec-archive-change/SKILL.md`, update the
      archive step to commit and push the archive commit to the change's
      branch (rather than leaving it local/on `main`), as the final step
      before merge.
- [x] 4.2 Mirror the same changes to
      `.gemini/skills/openspec-archive-change/SKILL.md` (or equivalent).

## 5. Documentation

- [x] 5.1 Rewrite the "Development Workflow" section of `CLAUDE.md` to
      describe the branch/draft-PR/self-review/feedback/archive/squash-merge
      lifecycle, including the `gh` CLI prerequisite and the branch-cleanup
      convention for abandoned changes.
- [x] 5.2 Mirror the same documentation changes to `GEMINI.md` per the Agent
      Config Sync section.

## 6. Bootstrap This Change Through the New Workflow

- [ ] 6.1 Once tasks 2-4 are complete, use the updated skills to create the
      branch `openspec/adopt-pr-review-workflow`, commit this change's
      artifacts plus the workflow/skill/doc edits, push, and open the PR for
      this change itself.
- [ ] 6.2 Run `/code-review` against the PR diff and address any findings.
- [ ] 6.3 Mark the PR ready for review and notify the user.
