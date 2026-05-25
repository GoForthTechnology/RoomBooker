## Why

The current deployment pipelines trigger based on commit messages starting with `Cut v...`. This approach is fragile because commit messages can be lost during squash merges, are subject to typos, and do not provide a formal record of releases in the repository. Transitioning to Git tag triggers (`v*`) is an industry-standard practice that makes deployments robust and provides clear versioning markers in Git.

## What Changes

- **Version Bump Script**: Update `scripts/bump_version.sh` to create and push a Git tag (e.g., `v1.2.15+43`) after bumping the version and committing.
- **Workflow Triggers**: Modify `.github/workflows/android-release.yml` and `.github/workflows/firebase-hosting-merge.yml` to trigger on tag pushes instead of branch pushes/commit messages.
- **Version Extraction**: Update the workflows to extract the version string from the Git tag name.

## Capabilities

### New Capabilities
- `cicd-tag-triggers`: Covers the logic for tagging releases and triggering pipelines based on those tags.

### Modified Capabilities
- `android-cicd`: Update the trigger mechanism for the Android release pipeline.

## Impact

- **`scripts/bump_version.sh`**: Changed push logic to include tags.
- **GitHub Workflows**: Structural changes to the `on:` triggers.
- **Developer Workflow**: No change to command usage (`./scripts/bump_version.sh -cp patch`), but the underlying Git behavior is improved.
