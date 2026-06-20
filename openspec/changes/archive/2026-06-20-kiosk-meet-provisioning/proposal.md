## Why

Kiosk instant bookings ("Quick Book") currently create a confirmed reservation without a Meet link, leaving the room's Join button permanently inactive. Auto-provisioning a Google Meet Space on Kiosk booking creation fulfills REQ-14 and REQ-18, completing the "In-Room Tactical Hub" vision from Phase 5 of the program plan.

## What Changes

- **New Cloud Function** `onKioskBookingCreated`: triggers on `confirmed-requests/{id}` creation, detects `bookedVia: 'kiosk'`, calls the Google Meet REST API to create a Meet Space, and writes the resulting URL to `request-details/{id}.meetingUrl`.
- **Failure path**: on Meet API failure or function timeout, the function writes a transient error document to `rooms/{roomID}/provisioning-errors/{id}` and deletes the booking, leaving the room available for retry.
- **New Kiosk dashboard states**: PROVISIONING (spinner while URL is pending), ERROR (error banner from error doc), and TIMEOUT (client-side 30s watchdog that self-cleans the booking and shows a banner).
- **New GCP/Terraform resources**: dedicated `meet-provisioner` service account with `meetings.space.created` scope and Google Meet API enabled; service account key stored in Secret Manager.
- **New Firestore rules**: Kiosk read/delete access to `rooms/{roomID}/provisioning-errors` scoped to its assigned room.

## Capabilities

### New Capabilities

- `kiosk-meet-provisioning`: Auto-provision a Google Meet Space when a Kiosk instant booking is created, including the full lifecycle: in-progress state, failure cleanup with error signaling, and client-side timeout.

### Modified Capabilities

- `kiosk-instant-booking`: Add provisioning lifecycle states (PROVISIONING, ERROR, TIMEOUT) to the Quick Book UX; the booking is no longer considered "complete" until a Meet URL is present or provisioning has failed.
- `kiosk-access-control`: Extend room-scoped Kiosk Firestore access to cover the new `provisioning-errors` subcollection (read + delete).

## Impact

- **Cloud Functions** (`functions/index.js`): new `onKioskBookingCreated` export.
- **Firestore rules** (`firestore.rules`): new rule for `provisioning-errors` subcollection.
- **Flutter / Kiosk** (`packages/roombooker_kiosk/lib/main.dart`): dashboard state machine extended with PROVISIONING, ERROR, and TIMEOUT states.
- **GCP / Terraform** (`terraform/`): new service account and Secret Manager secret.
- **No changes to `roombooker_portal` or `roombooker_core`.**
