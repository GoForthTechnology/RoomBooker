## 1. Script Updates

- [x] 1.1 Modify `scripts/bump_version.sh` to create an annotated tag after committing.
- [x] 1.2 Update `scripts/bump_version.sh` to push tags when the `-p` flag is used.

## 2. Workflow Refactoring

- [x] 2.1 Update `.github/workflows/android-release.yml` trigger to `push: tags: ['v*']`.
- [x] 2.2 Remove commit message `if` check from `android_release` job.
- [x] 2.3 Update `.github/workflows/firebase-hosting-merge.yml` trigger to `push: tags: ['v*']`.
- [x] 2.4 Update version extraction in both workflows to use `github.ref_name`.
- [x] 2.5 Make GitHub Release creation idempotent (handle existing tags).

## 3. Verification & Cleanup

- [x] 3.1 Trigger a version bump with `./scripts/bump_version.sh -cp patch` and verify tag creation.
- [ ] 3.2 Verify both Android and Web deployments trigger and complete successfully.
- [x] 3.3 Update `README.md` and `GEMINI.md` to reflect tag-based deployment.
