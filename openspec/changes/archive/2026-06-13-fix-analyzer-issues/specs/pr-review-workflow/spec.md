## MODIFIED Requirements

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
