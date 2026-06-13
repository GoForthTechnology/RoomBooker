## 1. CI/CD Pipeline Updates

- [x] 1.1 Add an "Extract Version Parts" step to `.github/workflows/android-release.yml` using `cut` on `github.ref_name`.
- [x] 1.2 Modify the existing "Upload to Google Play" step to explicitly target the `internal` track (this continues to run for all builds).
- [x] 1.3 Add a new "Promote to Production" step that mirrors the Internal upload but targets the `production` track.
- [x] 1.4 Add a conditional `if: steps.version.outputs.patch == '0'` to the Production upload step.

## 2. Validation & Documentation

- [x] 2.1 Verify yaml syntax using an external linter or by running `act` locally with a simulated tag push.
- [x] 2.2 Document the new "Patch = Internal, Minor = Prod" workflow convention in `GEMINI.md`.