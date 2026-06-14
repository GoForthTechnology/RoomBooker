## 1. CI Workflow

- [x] 1.1 Create `.github/workflows/firebase-backend-deploy.yml`, triggered
      on `push` to `main`, that checks out the repo, sets up Node 22, runs
      `npm ci` in `functions/`, decodes `FIREBASE_SERVICE_ACCOUNT_KEY` into a
      temporary credentials file (mirroring the base64-or-raw-JSON pattern
      used in `firebase-hosting-merge.yml`), and runs `firebase deploy --only
      functions,firestore:rules,firestore:indexes --project roombooker-5e947`
      with `GOOGLE_APPLICATION_CREDENTIALS` pointing at that file.
- [x] 1.2 Ensure the temporary credentials file is removed in an `if: always()`
      cleanup step.

## 2. Terraform Cleanup

- [x] 2.1 Remove `google_firebaserules_ruleset.firestore` and
      `google_firebaserules_release.firestore` from `terraform/firebase.tf`.
- [x] 2.2 Run `terraform state rm google_firebaserules_ruleset.firestore` and
      `terraform state rm google_firebaserules_release.firestore`.
- [x] 2.3 Run `terraform plan` and confirm it reports no unexpected changes.

## 3. Validation

- [x] 3.1 Lint/sanity-check the new workflow YAML (e.g. via `act` dry run or
      manual review against the existing hosting workflow's structure).
- [ ] 3.2 After merging to `main`, confirm the `firebase-backend-deploy`
      workflow run succeeds and that functions/rules/indexes deploy without
      errors.
