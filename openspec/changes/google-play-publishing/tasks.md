## 1. Infrastructure (Terraform)

- [x] 1.1 Add `google-play-deployer` service account to `terraform/iam.tf`.
- [x] 1.2 Assign necessary IAM roles for Google Play Android Developer API access.
- [x] 1.3 Add output for the Play Store service account key.
- [x] 1.4 Run `terraform apply` to provision the new service account.

## 2. CI/CD Pipeline Updates

- [x] 2.1 Update `.github/workflows/android-release.yml` to build `.aab` in addition to `.apk`.
- [x] 2.2 Configure `r0adkll/upload-google-play` action in the release workflow.
- [x] 2.3 Add `GOOGLE_PLAY_SERVICE_ACCOUNT_KEY` secret usage to the workflow.
- [x] 2.4 Set the initial track to `internal` for testing Play Store automation.

## 3. Verification & Documentation

- [x] 3.1 Perform a manual upload of the first `.aab` to the Play Console (User Action).
- [x] 3.2 Configure the `GOOGLE_PLAY_SERVICE_ACCOUNT_KEY` GitHub Secret using the Terraform output.
- [ ] 3.3 Trigger a version bump and verify both Firebase (APK) and Play Store (AAB) deployments.
- [x] 3.4 Update `README.md` and `GEMINI.md` with Play Store publishing instructions.
