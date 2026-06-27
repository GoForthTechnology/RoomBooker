## Why

Non-admin users have no way to propose changes to confirmed bookings — only
admins can edit them. This blocks the video conference link rollout (users
can't add a Meet URL to their own confirmed booking) and creates friction
whenever legitimate details change (time, room, event name) after a booking
is approved. The familiar admin review flow already exists; this change
threads non-admin edit proposals through it.

## What Changes

- Non-admin users can open a confirmed booking dialog and tap **Propose
  Change** to submit a full edit proposal (time, room, event details,
  meeting URL, recurrence scope).
- Confirmed bookings with a pending amendment show a visual indicator to all
  users. Admins are blocked from direct edits on that booking until the
  amendment is resolved.
- Proposed amendments appear in the existing **Pending** queue on the admin
  review screen, visually distinguished from new booking requests.
- Admins review a diff (current vs. proposed) and can **Apply** or
  **Reject** the amendment. Only admins can reject; non-admins cannot
  withdraw.
- Applying an amendment updates the confirmed booking and its private
  details atomically; rejecting clears the amendment without changing the
  booking.
- A notification email is sent to the `bookingCreated` target when an
  amendment is proposed, with content that serves both as a confirmation to
  the original requestor and as a security alert with a challenge step for
  anyone who did not initiate the change.
- Amendment events are added to the existing request log.
- New `amendmentProposed`, `amendmentApproved`, and `amendmentRejected`
  notification events are introduced (all defaulting to the same target as
  `bookingCreated`).

## Capabilities

### New Capabilities

- `booking-amendments`: Amendment proposal lifecycle — submission by
  non-admins, admin diff review inside the Pending queue, approval/rejection,
  logging, and notifications. Includes Firestore schema (`amendment-details`
  collection), security rule carve-outs, and all UI entry points.

### Modified Capabilities

- `data-model`: New `BookingAmendment` entity; `hasPendingAmendment` flag
  added to the `Request` entity; three new `NotificationEvent` values.
- `booking-service`: New amendment operations (`submitAmendment`,
  `applyAmendment`, `rejectAmendment`, `getAmendment`) added to
  `BookingService` and `BookingRepo`.

## Impact

- **roombooker_core**: New entity `BookingAmendment`; `Request` gains
  `hasPendingAmendment`; `BookingService` and `BookingRepo` gain amendment
  methods; `NotificationEvent` enum extended.
- **roombooker_portal**: Confirmed-booking dialog gains "Propose Change"
  entry point and "pending" indicator; `RequestEditorViewModel` extended for
  amendment submission; new amendment diff widget in the Pending list.
- **firestore.rules**: New `amendment-details` collection rule; carve-out on
  `confirmed-requests` allowing authenticated non-admins to set the
  `hasPendingAmendment` flag.
- **No breaking changes** to existing booking or kiosk flows.
