## ADDED Requirements

### Requirement: Continuous Backend Deployment on Main
The CI/CD pipeline MUST automatically deploy Cloud Functions and Firestore
security rules and indexes to the `roombooker-5e947` Firebase project
whenever a commit is pushed to the `main` branch.

#### Scenario: Push to main triggers backend deploy
- **WHEN** a commit is pushed (including via PR merge) to the `main` branch
- **THEN** a CI workflow SHALL run `firebase deploy --only
  functions,firestore:rules,firestore:indexes --project roombooker-5e947`
  using the contents of the `functions/` directory and the repository's
  `firestore.rules` and `firestore.indexes.json` files.

#### Scenario: Deploy authenticates without local Firebase CLI login
- **WHEN** the backend deploy workflow runs
- **THEN** it SHALL authenticate to Firebase using a service account key
  provided via a GitHub Actions secret (`FIREBASE_SERVICE_ACCOUNT_KEY`) and
  `GOOGLE_APPLICATION_CREDENTIALS`, and MUST NOT require any interactive
  `firebase login` or locally-stored user credentials.

### Requirement: Single Ownership of Firestore Rules Deployment
Firestore security rules deployment SHALL be owned exclusively by the CI
backend-deploy workflow described above. Terraform MUST NOT manage or deploy
Firestore rules releases.

#### Scenario: Terraform apply does not affect Firestore rules
- **WHEN** `terraform apply` is run against the project's Terraform
  configuration
- **THEN** it SHALL NOT create, modify, or release any Firestore rules
  ruleset, and the live Firestore rules SHALL remain whatever was most
  recently deployed by the CI backend-deploy workflow.

### Requirement: Hosting Deploy Remains Tag-Triggered
The existing hosting (web build) deployment SHALL continue to be triggered
only by version tag pushes, independent of the new main-triggered backend
deploy.

#### Scenario: Push to main does not redeploy hosting
- **WHEN** a commit is pushed to `main` without an accompanying version tag
- **THEN** the hosting deployment workflow SHALL NOT run, and only the
  backend deploy workflow (functions and Firestore rules/indexes) SHALL run.
