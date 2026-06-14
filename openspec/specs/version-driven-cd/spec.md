# Version-Driven CD Specification: Room Booker

## Purpose
This document specifies how semantic version tags route Android builds to
Google Play Internal/Production deployment tracks via the CI/CD pipeline.

## [CD-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

## Requirements

### Requirement: Semantic Version Routing
The CI/CD pipeline MUST route application builds to specific deployment tracks based on the semantic versioning tag that triggered the build.

#### Scenario: Route Patch Release to Internal
- **WHEN** a git tag is created with a `Patch` version bump (e.g., `v1.3.1`)
- **THEN** the Android pipeline SHALL build the AAB and upload it EXCLUSIVELY to the Google Play Console `Internal` track.

#### Scenario: Route Minor Release to Production
- **WHEN** a git tag is created with a `Minor` version bump (e.g., `v1.4.0`)
- **THEN** the Android pipeline SHALL build the AAB and upload it to BOTH the Google Play Console `Internal` track AND the `Production` track.

#### Scenario: Route Major Release to Production
- **WHEN** a git tag is created with a `Major` version bump (e.g., `v2.0.0`)
- **THEN** the Android pipeline SHALL build the AAB and upload it to BOTH the Google Play Console `Internal` track AND the `Production` track.