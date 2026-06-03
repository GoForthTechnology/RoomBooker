# Monorepo Workspace Specification: Room Booker

## Purpose
This document defines the requirements and constraints for the monorepo structure, ensuring code sharing, application isolation, and consistent dependency management across the project.

## [WKSP-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

## Requirements

### Requirement: Workspace Structure
The project MUST be structured as a Flutter monorepo workspace to manage multiple applications and shared packages.

#### Scenario: Verify Workspace Configuration
- **WHEN** checking the root `pubspec.yaml`
- **THEN** it MUST contain a `workspace` or `melos` configuration (depending on the chosen tool) that includes `packages/*`.

### Requirement: Shared Domain Logic Isolation
All shared data entities, repositories, and domain services MUST be isolated into a dedicated `roombooker_core` package.

#### Scenario: Verify Core Package Contents
- **WHEN** inspecting `packages/roombooker_core/lib/`
- **THEN** it MUST contain the data services (e.g., `BookingService`, `AuthService`) and domain entities.

### Requirement: Application Isolation
The primary user-facing application MUST be isolated into a dedicated `roombooker_portal` package.

#### Scenario: Verify Portal Package Contents
- **WHEN** inspecting `packages/roombooker_portal/lib/`
- **THEN** it MUST contain the UI components, screens, and application-specific entry point (`main.dart`).

### Requirement: Dependency Management
Applications MUST depend on `roombooker_core` using relative path dependencies.

#### Scenario: Verify Portal Dependency
- **WHEN** checking `packages/roombooker_portal/pubspec.yaml`
- **THEN** it MUST contain a dependency on `roombooker_core: { path: ../roombooker_core }`.

### Requirement: CI/CD Path Alignment
The GitHub Actions workflows MUST be updated to build and deploy from the new package paths without breaking existing functionality.

#### Scenario: Verify Android Build Path
- **WHEN** the `android-release.yml` workflow runs
- **THEN** it MUST execute build commands within the `packages/roombooker_portal` directory or with appropriate path flags.

#### Scenario: Verify Firebase Hosting Build Path
- **WHEN** the `firebase-hosting-merge.yml` workflow runs
- **THEN** it MUST build the web application from the `packages/roombooker_portal` directory.
