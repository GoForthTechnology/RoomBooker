## 1. Infrastructure (Terraform)

- [x] 1.1 Create `terraform/` directory and basic provider configuration.
- [x] 1.2 Configure GCS remote backend for Terraform state.
- [x] 1.3 Define Firebase project and Android app resources in Terraform.
- [x] 1.4 Create service account for CI/CD with necessary IAM roles.
- [x] 1.5 Run `terraform init` and `terraform apply` to provision resources.

## 2. Android Signing & Build Setup

- [x] 2.1 Generate production Android keystore locally (to be shared with user).
- [x] 2.2 Encode keystore to Base64 and prepare secrets for GitHub.
- [x] 2.3 Update `android/app/build.gradle.kts` to use environment variables for signing.
- [ ] 2.4 Verify local signed build using the new environment variable setup.

## 3. CI/CD Pipeline Automation

- [x] 3.1 Create `android-release.yml` GitHub Actions workflow.
- [x] 3.2 Implement build job: setup Flutter, build .aab with signing.
- [x] 3.3 Implement distribution job: upload .aab to Firebase App Distribution.
- [x] 3.4 Integrate workflow with existing `bump_version.sh` trigger.

## 4. Verification & Documentation

- [ ] 4.1 Trigger a version bump and verify the end-to-end Android pipeline.
- [ ] 4.2 Confirm build availability in Firebase App Distribution.
- [x] 4.3 Update `README.md` or `GEMINI.md` with CI/CD and IaC documentation.
