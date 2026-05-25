## Context

Currently, the release process is:
1. `bump_version.sh` updates `pubspec.yaml`, commits with `Cut v...`, and pushes.
2. GitHub Actions sees the commit message and runs the build.

If the commit message is squashed or mistyped, the build never runs.

## Goals / Non-Goals

**Goals:**
- Reliable triggers that survive Git history rewrites/squashing.
- Proper Git tagging for every release.
- Unified trigger logic for Web and Android.

**Non-Goals:**
- Changing the versioning format (`1.2.x+y`).
- Changing the distribution channels (Firebase/Play Store).

## Decisions

### 1. Annotated Tags
- **Decision**: Use annotated tags (`git tag -a v... -m "..."`) instead of lightweight tags.
- **Rationale**: Annotated tags store creator information, date, and a message, which is better for release tracking and can be used to generate release notes in GitHub.

### 2. Tag Format
- **Decision**: Prefix tags with `v` (e.g., `v1.2.14+42`).
- **Rationale**: Standard convention that clearly distinguishes version tags from other potential tags.

### 3. Workflow Trigger Update
- **Decision**: Move from `on: push: branches: [main]` with a message filter to `on: push: tags: ['v*']`.
- **Rationale**: This is the native GitHub Actions way to handle release-based deployments.

### 4. Handling Existing Releases
- **Decision**: Use `gh release create --generate-notes` with error handling or check for existence.
- **Rationale**: When switching to tag triggers, the tag already exists when the action starts. The `gh release create` command should be updated to handle cases where a release for that tag might have been partially created or needs updating, using the `--generate-notes` flag or a conditional check to avoid "already exists" errors.
