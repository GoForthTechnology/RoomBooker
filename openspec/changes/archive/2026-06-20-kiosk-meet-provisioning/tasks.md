## 1. GCP & Terraform: Service Account + Meet API

- [x] 1.1 Add a `meet-provisioner` service account resource to `terraform/` and grant it the `roles/meet.spaceCreator` IAM role (or the equivalent `meetings.space.created` OAuth scope binding)
- [x] 1.2 Enable the Google Meet API (`meet.googleapis.com`) in the GCP project via Terraform (`google_project_service`)
- [x] 1.3 Create a service account key and store it in Secret Manager as `meet-provisioner-key`; add the Secret Manager secret resource to Terraform
- [x] 1.4 Run `terraform apply` and verify the service account, API enablement, and secret exist in the GCP Console

## 2. Cloud Functions: `onKioskBookingCreated`

- [x] 2.1 Install the `googleapis` npm package in `functions/` to access the Meet REST API client
- [x] 2.2 Add a helper in `functions/` that loads the `meet-provisioner` service account key from Secret Manager (or `functions.config()`) and returns an authenticated Meet API client
- [x] 2.3 Implement `onKioskBookingCreated` in `functions/index.js`: listen to `onCreate` on `orgs/{orgID}/confirmed-requests/{bookingID}`, exit early if `bookedVia !== 'kiosk'`, and check idempotency guard (`meetingUrl` already set in `request-details/{id}`)
- [x] 2.4 Add the Meet Space creation call (`meet.spaces.create`) in the success path and write the returned `meetingUri` to `orgs/{orgID}/request-details/{bookingID}.meetingUrl`
- [x] 2.5 Add the failure path: catch all errors, write a `provisioning-errors` document to `orgs/{orgID}/rooms/{roomID}/provisioning-errors/{auto-id}` with `{ bookingID, message, timestamp }`, then delete `confirmed-requests/{bookingID}` and `request-details/{bookingID}`
- [x] 2.6 Set `timeoutSeconds: 15` on the `onKioskBookingCreated` function definition
- [x] 2.7 Write or update tests in `functions/test/` covering: non-kiosk booking is ignored, successful Meet creation writes URL, Meet API failure triggers cleanup and error doc, idempotency guard skips API when URL already set

## 3. Firestore Rules: Provisioning Error Access

- [x] 3.1 Add a Firestore security rule for `orgs/{orgID}/rooms/{roomID}/provisioning-errors/{docID}` granting read and delete to a Kiosk with a valid `kiosk-grants/{uid}` for the same `roomID`, and denying all client writes (create/update)
- [x] 3.2 Verify the new rule does not grant access to Kiosks for other rooms or to unauthenticated clients

## 4. Flutter / Kiosk: Provisioning State Machine

- [x] 4.1 In `packages/roombooker_kiosk/lib/main.dart`, add a Firestore stream subscription in the dashboard widget for `orgs/{orgID}/rooms/{roomID}/provisioning-errors`, storing the list of error docs in local state
- [x] 4.2 Add the PROVISIONING state: when the current booking has `bookedVia == 'kiosk'` and `meetingUrl == null` (and no error doc is active), render a loading indicator with a "Generating Meet link…" message in place of the JOIN button
- [x] 4.3 Add the ERROR state: when one or more provisioning error docs exist for the room, render an error banner over the dashboard with the `message` from the first error doc and an "OK" dismiss button; on dismiss, delete the error doc from Firestore and clear the banner
- [x] 4.4 Add the client-side 30-second watchdog: start a `Timer` immediately after `_onQuickBook` succeeds; cancel the timer if `meetingUrl` becomes non-null or an error doc appears; if the timer fires, delete `confirmed-requests/{bookingID}` and show a timeout banner with a "Retry" dismiss that returns to the AVAILABLE state
- [x] 4.5 Ensure all three new states (PROVISIONING, ERROR, TIMEOUT) are covered by widget tests in `packages/roombooker_kiosk/`

## 5. Deploy & Validate

- [x] 5.1 Deploy Cloud Functions: `firebase deploy --only functions`
- [x] 5.2 Deploy Firestore rules: `firebase deploy --only firestore:rules`
- [ ] 5.3 Build and install a debug Kiosk APK on the test device
- [x] 5.4 End-to-end test: tap a Quick Book button, observe PROVISIONING spinner, confirm JOIN button appears with a valid `meet.google.com` URL
- [ ] 5.5 Failure test: temporarily misconfigure the Meet API key, tap Quick Book, confirm PROVISIONING state appears then transitions to ERROR banner, room returns to AVAILABLE after dismissal
- [ ] 5.6 Timeout test: simulate CF delay (e.g., disable network temporarily), confirm the 30-second watchdog fires, timeout banner appears, and the booking is cleaned up
