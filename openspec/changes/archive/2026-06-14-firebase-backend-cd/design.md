## Context

Today, the only automated Firebase deployment is hosting (web build), and it
runs only on version tag pushes via `firebase-hosting-merge.yml`, using the
`GOOGLE_PLAY_SERVICE_ACCOUNT_KEY` secret (a service account scoped for Play
Store + App Distribution, which also happens to have
`roles/firebasehosting.admin`).

Cloud Functions (`functions/`, Firebase Functions v1, Node 22) have never had
a CI deploy path — they are only deployable via `firebase deploy --only
functions` run locally, which is currently blocked by local Firebase CLI auth
issues.

Firestore rules (`firestore.rules`) and indexes (`firestore.indexes.json`)
are currently applied as a side effect of `terraform apply`, via
`google_firebaserules_ruleset.firestore` and
`google_firebaserules_release.firestore` in `terraform/firebase.tf`. Terraform
embeds the rules file content directly (`file("../firestore.rules")`) and
creates a new ruleset + release whenever that content changes.

Terraform already provisions a `github-actions-deployer` service account
(`google_service_account.github_actions` in `terraform/iam.tf`) with:
- `roles/firebase.admin`
- `roles/firebaseappdistro.admin`
- `roles/serviceusage.serviceUsageConsumer`
- `roles/iam.serviceAccountUser`

Its key is output as `service_account_key` and is presumed to be stored in
the `FIREBASE_SERVICE_ACCOUNT_KEY` GitHub secret (not currently used by any
workflow).

## Goals / Non-Goals

**Goals:**
- Deploy Cloud Functions to `roombooker-5e947` automatically on every push to
  `main`.
- Deploy Firestore rules and indexes automatically on every push to `main`.
- Remove the dependency on local `firebase login` / Application Default
  Credentials for these deployments.
- Establish a single owner (CI) for the live Firestore rules release, so
  Terraform and CI don't overwrite each other's deploys.

**Non-Goals:**
- Changing the hosting deploy trigger or credentials (stays tag-based, using
  `GOOGLE_PLAY_SERVICE_ACCOUNT_KEY`).
- Migrating Cloud Functions from v1 to v2.
- Adding staging/preview environments or a dedicated `firestore:rules` test
  step (rules are already covered by `functions/test/firestore.rules.test.js`
  in the existing PR-checks workflow, which is unchanged).
- Re-provisioning or rotating the `github-actions-deployer` service account
  key — this design assumes `FIREBASE_SERVICE_ACCOUNT_KEY` is already valid
  for that account. If it's stale, that's a manual `gh secret set` step
  outside this change.

## Decisions

### 1. New workflow file, triggered on push to `main`
A separate `firebase-backend-deploy.yml` (rather than extending
`firebase-hosting-merge.yml`) because:
- The trigger is different (push to `main` vs. tag push).
- The credentials are different (`FIREBASE_SERVICE_ACCOUNT_KEY` vs.
  `GOOGLE_PLAY_SERVICE_ACCOUNT_KEY`).
- It keeps the Android/hosting release flow (which already has many steps:
  tests, build, Sentry upload, GitHub release) decoupled from backend infra
  deploys, so a functions/rules change ships immediately without waiting for
  a version bump, and a release tag doesn't redundantly redeploy
  functions/rules that haven't changed.

### 2. Single `firebase deploy` invocation for functions + rules + indexes
`firebase deploy --only functions,firestore:rules,firestore:indexes
--project roombooker-5e947` deploys all three targets in one command. This
keeps the workflow simple; if one target fails, the whole deploy step fails
visibly in the Actions log, which is the desired signal (any partial-deploy
investigation is a manual follow-up, not something CI needs to special-case).

### 3. Reuse `github-actions-deployer` SA via `FIREBASE_SERVICE_ACCOUNT_KEY`
This SA already has `roles/firebase.admin`, which covers Firestore rules
deploy, Cloud Functions deploy, and `roles/iam.serviceAccountUser` (needed
for Cloud Functions to act as the runtime service account). No new IAM grants
or service accounts are needed. The credential is provided via
`GOOGLE_APPLICATION_CREDENTIALS` pointing at a temporary JSON file, matching
the pattern already used in `firebase-hosting-merge.yml` and
`android-release.yml`.

### 4. Remove Firestore rules management from Terraform
`google_firebaserules_ruleset.firestore` and
`google_firebaserules_release.firestore` are removed from
`terraform/firebase.tf`, and `terraform state rm` is run for both (not
`terraform destroy`, since that would delete the live ruleset/release that
CI's first deploy hasn't necessarily replaced yet). After this:
- `firestore.rules` remains the single source of truth in the repo.
- CI's `firebase deploy --only firestore:rules` becomes the only mechanism
  that creates new rulesets/releases.
- Future `terraform apply` runs no longer touch Firestore rules at all.

Alternative considered: keep Terraform as the rules deploy mechanism and have
CI only handle functions. Rejected because the user's stated goal is for
*all* of hosting/functions/rules to be CI-managed, and because mixing a
manual `terraform apply` step into the loop reintroduces the same
local-auth friction this change is meant to eliminate.

## Risks / Trade-offs

- **[Risk]** `FIREBASE_SERVICE_ACCOUNT_KEY` may not actually correspond to the
  `github-actions-deployer` SA (it was created independently of this change).
  → **Mitigation**: First CI run on `main` will fail fast with an auth/permission
  error if the key is wrong or the SA lacks a role; this is visible in the
  Actions log and fixable via `terraform output -raw service_account_key | gh
  secret set FIREBASE_SERVICE_ACCOUNT_KEY` without further code changes.

- **[Risk]** Removing Terraform's Firestore rules resources leaves a window
  where, between merging this change and the first successful CI deploy on
  `main`, the rules in Firestore are whatever was last applied by Terraform
  (unchanged, just no longer tracked). → **Mitigation**: No live behavior
  changes at merge time — `terraform state rm` doesn't alter the deployed
  ruleset/release, it only stops Terraform from tracking it. The first
  `firebase deploy --only firestore:rules` on the next push to `main`
  (typically this change's own merge) becomes the new source of truth.

- **[Risk]** Every push to `main` now triggers a real deploy to production
  Firebase resources (functions + rules), with no staging gate. →
  **Mitigation**: `main` is already protected by the existing `pr-checks.yml`
  (analyze + tests required before merge), so this matches the existing bar
  for hosting deploys on tags. Out of scope to add a staging environment here.

## Migration Plan

1. Add `.github/workflows/firebase-backend-deploy.yml`.
2. Remove the two `google_firebaserules_*` resources from
   `terraform/firebase.tf`.
3. Run `terraform state rm google_firebaserules_ruleset.firestore` and
   `terraform state rm google_firebaserules_release.firestore`.
4. Run `terraform plan` to confirm no other resources are affected (expect
   "No changes" or only the removal already reflected by the state rm).
5. Merge to `main`, which triggers the new workflow as its first real run —
   monitor the Actions log for the `firebase deploy` step to confirm
   functions and rules deploy successfully.

**Rollback**: If the new workflow fails or deploys something undesired,
revert the PR. The Terraform resources can be re-added and
`terraform import`ed back if needed, though in practice `firebase deploy`
remaining as the rules-deploy mechanism is the intended end state regardless.

## Open Questions

- None outstanding. If `FIREBASE_SERVICE_ACCOUNT_KEY` turns out not to be the
  `github-actions-deployer` key, that's a secret-rotation task handled
  outside this change (see Risks).
