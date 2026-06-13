## Context

The RoomBooker Android application is currently deployed via GitHub Actions using a manual promotion model. Every tagged release triggers a build that is uploaded to the Google Play Console's "Internal" track. An administrator must then log into the Play Console and manually promote the build to "Production". This creates unnecessary friction for feature releases. We want to use our semantic versioning (`vMajor.Minor.Patch`) as a deterministic routing mechanism for our CI/CD pipeline.

## Goals / Non-Goals

**Goals:**
*   Automate the deployment of Android builds to the Production track when a Minor or Major version is tagged.
*   Retain the Internal track for Patch versions to allow for safe, rapid testing of fixes or exploratory builds.
*   Implement this routing entirely within the existing GitHub Actions workflow without requiring external scripts.

**Non-Goals:**
*   We are not changing the Web deployment strategy (Firebase Hosting) in this phase; it will continue to deploy on all tagged releases.
*   We are not implementing complex staged rollouts (e.g., 10% -> 50% -> 100%) at this time; Minor/Major pushes will be 100% rollouts.

## Decisions

### Decision 1: Bash Scripting for Version Parsing in CI
*   **Choice:** We will use bash string manipulation (`cut`) within a GitHub Actions step to extract the patch number from `github.ref_name`.
*   **Rationale:** It is lightweight, requires no external dependencies, and integrates seamlessly into the workflow's conditional (`if`) statements.
*   **Alternatives Considered:** Creating a custom GitHub Action or modifying `bump_version.sh` to output environment variables. These were rejected as they add unnecessary complexity; the tag name itself contains all the required routing information.

### Decision 2: Dual Upload Steps
*   **Choice:** We will define two separate `r0adkll/upload-google-play@v1` steps in the workflow. One for Internal (which always runs) and one for Production (which runs conditionally).
*   **Rationale:** Google Play allows a build to exist on both tracks. Pushing to Internal on *every* build ensures a continuous history for testers, while conditionally pushing the exact same artifact to Production satisfies the automation goal.

## Risks / Trade-offs

*   **[Risk] Accidental Production Deployments**: A developer might tag a `Minor` release when they intended to just test a risky feature.
    *   **Mitigation**: The team must adopt a strict semantic understanding: "Patch = Test, Minor/Major = Ship".
*   **[Trade-off] Patch Hotfixes**: If a critical bug is found in Production, a `Patch` release will only automatically go to Internal. It will require a manual promotion to reach users.
    *   **Mitigation**: This is accepted. The friction is preserved specifically for scenarios where manual verification of the fix might be desired before wide release.