## 1. Android Configuration

- [x] 1.1 Add `xmlns:tools="http://schemas.android.com/tools"` to the `<manifest>` tag in `android/app/src/main/AndroidManifest.xml`.
- [x] 1.2 Add `<uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove" />` before the `<application>` tag.
- [x] 1.3 Add `<meta-data android:name="google_analytics_adid_collection_enabled" android:value="false" />` inside the `<application>` tag.

## 2. Verification

- [x] 2.1 Run `flutter build appbundle --release` to ensure the project still builds.
- [x] 2.2 Verify that the `AD_ID` permission is not present in the merged manifest (manual check or build validation).

## 3. Documentation

- [x] 3.1 Create `openspec/specs/privacy-stance/spec.md` as the official documentation of the privacy stance.
