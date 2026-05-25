## ADDED Requirements

### Requirement: Tagged Releases
The system SHALL create an annotated Git tag for every successful version bump.

#### Scenario: Tag Creation
- **WHEN** the `bump_version.sh` script is run with the `-c` (commit) flag
- **THEN** it creates a Git commit for the version change
- **AND** it creates an annotated Git tag with the name `v<version>`

### Requirement: Tag Triggered Deployment
The CI/CD pipelines SHALL be triggered when a tag matching the pattern `v*` is pushed to the repository.

#### Scenario: Pipeline Trigger
- **WHEN** a tag named `v1.2.14+42` is pushed to GitHub
- **THEN** the Android and Web release workflows are initiated
