## Why

Firestore security rules, indexes, and Cloud Functions currently have no
automated deployment path. Functions have never been deployed to the
`roombooker-5e947` project via CI, and Firestore rules are only applied as a
side effect of `terraform apply`, which is run manually and is also blocked
on local Firebase CLI authentication issues. The maintainer needs a path that
deploys backend changes (functions, rules, indexes) automatically from CI,
without depending on local `firebase login` credentials.

## What Changes

- Add a new GitHub Actions workflow, `firebase-backend-deploy.yml`, triggered
  on push to `main`, that:
  - Installs Cloud Functions dependencies (`npm ci` in `functions/`).
  - Authenticates to Firebase using the existing `github-actions-deployer`
    service account (`FIREBASE_SERVICE_ACCOUNT_KEY` secret), which already
    has `roles/firebase.admin` and `roles/iam.serviceAccountUser`.
  - Runs `firebase deploy --only functions,firestore:rules,firestore:indexes
    --project roombooker-5e947`.
- **BREAKING**: Remove the Terraform-managed `google_firebaserules_ruleset`
  and `google_firebaserules_release` resources from `terraform/firebase.tf`,
  and run `terraform state rm` for both. Firestore rules will now be deployed
  exclusively via the new CI workflow, eliminating the conflict where
  `terraform apply` would otherwise overwrite the rules deployed by CI (and
  vice versa).
- The existing tag-triggered `firebase-hosting-merge.yml` workflow (hosting +
  Android release) is unchanged; hosting continues to deploy only on version
  tags, while functions/rules now deploy continuously from `main`.

## Capabilities

### New Capabilities
- `firebase-backend-cd`: Specifies how pushes to `main` trigger automated
  deployment of Cloud Functions and Firestore rules/indexes to the Firebase
  project, including the authentication mechanism and ownership boundary
  between CI and Terraform for Firestore rules.

### Modified Capabilities
- (none — `version-driven-cd` covers Android tag-based releases and is
  unaffected by this change)

## Impact

- **New file**: `.github/workflows/firebase-backend-deploy.yml`
- **Modified file**: `firebase.json` (add a `functions` config block so
  `firebase deploy --only functions` has a deploy target)
- **Modified file**: `terraform/firebase.tf` (remove firebaserules
  ruleset/release resources)
- **Terraform state**: `terraform state rm google_firebaserules_ruleset.firestore`
  and `terraform state rm google_firebaserules_release.firestore`
  (non-destructive — stops Terraform tracking, does not delete the live
  ruleset/release)
- **Secrets**: Reuses existing `FIREBASE_SERVICE_ACCOUNT_KEY` secret; no new
  secrets required.
- **Systems**: GitHub Actions CI, Firebase project `roombooker-5e947`
  (Cloud Functions, Firestore rules/indexes).
