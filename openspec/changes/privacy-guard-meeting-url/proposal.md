## Why

Video conference links (`meetingUrl`) are currently stored directly on the
`Request` document in the `confirmed-requests` collection, which is publicly
readable (`allow read: if true`). This exposes Meet/Teams/Zoom join links —
and thus the ability to join a private meeting — to anyone who can read the
public calendar. Phase 4's "Tactical Hub" work (instant booking, kiosk
auto-provisioning) depends on links living in the already-room-scoped
`PrivateRequestDetails` record instead (REQ-12), and is a prerequisite for
Phase 4d (Instant Booking).

## What Changes

- Add a `meetingUrl` field to `PrivateRequestDetails` (entity, JSON
  (de)serialization, `copyWith`, `==`/`hashCode`).
- **BREAKING (data)**: Remove the `meetingUrl` field from `Request` — new
  writes (`submitBookingRequest`, `updateBooking`, `addBooking`) no longer
  set it on the public `Request`/`confirmed-requests` document.
- Add a one-time migration step that copies any existing
  `confirmed-requests.meetingUrl` value into the corresponding
  `PrivateRequestDetails.meetingUrl`, run as part of `4a` rollout before the
  `Request.meetingUrl` field is removed from the deployed app, so no
  in-flight links are lost.
- Update the Portal request editor (`request_editor_view_model.dart`,
  `request_editor.dart`) to read/write `meetingUrl` via
  `PrivateRequestDetails` instead of `Request`.
- Update the Kiosk dashboard (`roombooker_kiosk/lib/main.dart`) to read the
  "Join Meeting" URL from `PrivateRequestDetails` (already room-scoped and
  readable per REQ-13 / `kiosk-access-control`) instead of
  `Request.meetingUrl`.
- Update `BookingService`/`BookingRepo` enrichment so consumers that already
  fetch `PrivateRequestDetails` (e.g. the Kiosk's current-booking lookup) get
  `meetingUrl` alongside the other private fields.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `data-model`: `PrivateRequestDetails` gains a `meetingUrl` field; the
  `Request` entity no longer carries `meetingUrl`; add a migration
  requirement covering the one-time backfill of existing
  `confirmed-requests.meetingUrl` values.

## Impact

- **Code**: `packages/roombooker_core/lib/data/entities/request.dart` (+
  generated `request.g.dart`), `packages/roombooker_core/lib/data/repos/booking_repo.dart`,
  `packages/roombooker_core/lib/data/services/booking_service.dart`,
  `packages/roombooker_portal/lib/ui/widgets/request_editor/*`,
  `packages/roombooker_kiosk/lib/main.dart`.
- **Data**: One-time migration of `confirmed-requests` documents with a
  non-null `meetingUrl` into `private-request-details/{requestID}`.
- **Tests**: Update unit/widget tests across `roombooker_core` and
  `roombooker_portal` that construct `Request`/`PrivateRequestDetails` with
  `meetingUrl`.
- **Security rules**: No change required — `PrivateRequestDetails` access is
  already room-scoped for admins and kiosks (REQ-13, `kiosk-access-control`).
