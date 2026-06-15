## Context

The Kiosk Dashboard (`_KioskDashboardState` in
`packages/roombooker_kiosk/lib/main.dart`, extended in Phase 4b) already
streams every confirmed booking for the assigned room for the current local
day, sorted chronologically for `AgendaListView`. It derives `currentBooking`
(start <= now < end) and shows AVAILABLE/OCCUPIED.

REQ-16/17 ask for "Quick Book" buttons that instantly create an
auto-confirmed booking for the room when it's available. REQ-21 asks for an
attributable "In-Room User" identity for such bookings; 4c did not create
one (Kiosk auth remains anonymous; `RequestLogEntry.adminEmail` is sourced
from `FirebaseAuth.instance.currentUser?.email`, which is null for an
anonymous user). The user has confirmed a lightweight attribution label is
sufficient — no new Firebase Auth account or admin record.

REQ-18 (auto-attach a Meet URL to Kiosk-originated instant bookings) depends
on the Phase 5 auto-provisioning trigger, which doesn't exist yet, so Quick
Book bookings are created without a `meetingUrl`.

## Goals / Non-Goals

**Goals:**
- "Quick Book" buttons (15m/30m/60m) on the Kiosk Dashboard, visible only
  when the room is AVAILABLE.
- Buttons reflect the actual available gap: a duration that would overlap
  the next confirmed booking is disabled or hidden.
- Tapping a button creates an auto-confirmed `confirmed-requests` document
  for the assigned room, starting now, via `BookingService.addBooking`.
- Kiosk-originated bookings are distinguishable from regular bookings in
  the Portal (REQ-21, lightweight): a `bookedVia` field on `Request`, shown
  as "Booked via Kiosk" in place of an admin email in log/agenda views.

**Non-Goals:**
- No Meet URL auto-provisioning (REQ-18) — deferred to Phase 5.
- No new Firebase Auth identity, `Organization.systemUserID`, or
  admin-equivalent user record — superseded by the lightweight `bookedVia`
  label per user decision.
- No changes to Firestore rules — `kiosk-access-control` (REQ-20) already
  authorizes the Kiosk to create `confirmed-requests` for its own room.
- No "extend meeting" / "end early" controls (Phase 5: Proactive Feedback).
- No booking durations other than 15/30/60 minutes.

## Decisions

### 1. Gap computation reuses the existing day-scoped booking stream
`_KioskDashboardState` already has `bookings` (today's confirmed requests,
sorted). The "available gap" is `[now, nextBooking.eventStartTime)` where
`nextBooking` is the first booking with `eventStartTime.isAfter(now)`, or
unbounded (end of day) if none exists. A Quick Book duration `d` is enabled
iff `now.add(d) <= gapEnd` (or no `nextBooking` at all).

Alternative considered: a dedicated `BookingService` method for "next free
slot". Rejected — the data is already in hand from the 4b agenda stream;
adding a new repo/service method would duplicate that query for no benefit.

### 2. New `QuickBookPanel` widget
Add `packages/roombooker_kiosk/lib/quick_book_panel.dart`: a stateless
widget taking the day's `bookings`, `now`, `orgID`, `roomID`, and a callback
`onBook(Duration)`. It computes the gap (Decision 1) and renders three
buttons (15m/30m/60m), disabling any whose duration doesn't fit. Rendered
only when `status == RoomStatus.available`, alongside the existing hero
section.

### 3. Booking creation via `BookingService.addBooking`
`_KioskDashboardState` builds:
- `Request(eventStartTime: now, eventEndTime: now.add(duration), roomID,
  roomName, publicName: "In-Room Booking", status: RequestStatus.confirmed,
  bookedVia: BookingSource.kiosk)`
- `PrivateRequestDetails(name: "In-Room Hub", email: "", phone: "",
  message: "", eventName: "In-Room Booking", meetingUrl: null)`

and calls `_bookingService.addBooking(orgID, request, privateDetails)`,
which performs a transactional create of both documents (existing
`BookingRepo.addBooking` / `_addBooking`). This is the same auto-confirm
path used elsewhere (e.g. admin "Add Booking"), so no repo changes are
needed beyond the new `bookedVia` field round-tripping through
`json_serializable`.

`addBooking`'s post-write `_log` call sets `adminEmail` from
`FirebaseAuth.instance.currentUser?.email`, which is `null` for the Kiosk's
anonymous user — this is acceptable; the Portal distinguishes Kiosk
bookings via `bookedVia`, not `adminEmail`.

### 4. `Request.bookedVia` field (new `BookingSource` enum)
Add `enum BookingSource { kiosk }` and `final BookingSource? bookedVia` to
`Request` (nullable, omitted/absent for all existing/portal-created
bookings — no migration needed). Regenerate `request.g.dart` via
`build_runner`.

### 5. Portal display of Kiosk attribution
In the Portal's request log/agenda rendering
(`packages/roombooker_portal/lib/ui/`), where an admin's email/name is
normally shown for an action's actor (per the `ui-ux` "Log Attribution
Visibility" requirement), if `request.bookedVia == BookingSource.kiosk`,
display "Booked via Kiosk" (or "In-Room Hub") instead of the (null) admin
email.

## Risks / Trade-offs

- **[Risk]** Two Kiosks (or a Kiosk + Portal admin) booking the same gap
  concurrently could race. → `addBooking` is a single transactional write
  of new documents (no read-then-write on existing state), so the worst
  case is two overlapping confirmed bookings — an existing
  possibility for any two concurrent bookings today (overlap handling /
  `ignoreOverlaps` already exists at the Portal level). Out of scope to
  add new conflict-resolution for this change.
- **[Risk]** `bookedVia` is a new enum field threaded through
  `json_serializable` codegen — a typo or missed regen could break
  deserialization. → Mitigated by running `dart run build_runner build
  --delete-conflicting-outputs` and the existing `roombooker_core` test
  suite (entity round-trip tests).
- **[Trade-off]** Quick Book durations are fixed at 15/30/60m per REQ-16;
  no custom-duration picker. Matches the spec and keeps the Kiosk UI
  one-tap.

## Migration Plan

No data migration: `bookedVia` is optional and absent on all existing
documents. Client-only + entity change; rollout via the existing Kiosk APK
distribution and normal Portal web deploy. No rollback concerns beyond
shipping new builds.

## Open Questions

None.
