## 1. Project Configuration

- [x] 1.1 Verify `org` and `project` slugs in `pubspec.yaml`.
- [x] 1.2 Set `upload_debug_symbols: true` and `upload_source_maps: true` in `pubspec.yaml`.

## 2. GitHub Actions Integration

- [x] 2.1 Update `flutter build web` in `.github/workflows/firebase-hosting-merge.yml` to use `--source-maps`.
- [x] 2.2 Add `dart run sentry_dart_plugin` step to the workflow.
- [x] 2.3 Add `SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}` to the workflow environment.

## 3. Documentation & Cleanup

- [x] 3.1 Update `README.md` with a "Deployment & Observability" section explaining the Sentry token requirement.
- [x] 3.2 Remove or comment out deprecated build steps in `Dockerfile`.

## 4. Validation

- [x] 4.1 Verify `flutter analyze` passes.
- [x] 4.2 Dry-run the Sentry plugin command locally (if token available).
