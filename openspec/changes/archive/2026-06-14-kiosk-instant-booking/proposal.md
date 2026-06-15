## Why

The Kiosk Dashboard (Phase 4b) shows the room's status and daily agenda but
offers no way to act on an available room. Per the Program Plan's "In-Room
Tactical Hub" vision and REQ-16/REQ-17, a user standing in an empty room
should be able to instantly claim it for 15/30/60 minutes directly from the
Kiosk. This is unblocked now that 4a (Privacy Guard) and 4c (Kiosk Device
Identity & Scoped Access) are done — the Kiosk has a room-scoped identity
and write access to `confirmed-requests` for its own room (REQ-20).

## What Changes

- New `kiosk-instant-booking` capability spec covering "Quick Book"
  (REQ-16), auto-confirmation (REQ-17), and In-Room User attribution
  (REQ-21).
- Add "Quick Book" buttons (15m / 30m / 60m) to the Kiosk Dashboard, shown
  only when the room is AVAILABLE.
- Compute the available gap from now until the next confirmed booking
  (using the same day-scoped booking data the Agenda View already fetches)
  and disable/hide any Quick Book duration that would overlap that next
  booking.
- On tap, create an auto-confirmed booking via `BookingService.addBooking`
  for the assigned room, for the selected duration starting now.
- **In-Room User attribution (REQ-21, lightweight)**: add a
  `bookedVia: BookingSource?` field to `Request` (e.g.
  `BookingSource.kiosk`), set to `kiosk` for Quick Book bookings. The
  Portal's agenda/log views display a "Booked via Kiosk" / "In-Room Hub"
  label for such requests instead of an admin email. No new Firebase Auth
  account, org-level admin record, or Firestore rule changes — REQ-20
  (kiosk-access-control) already authorizes the write.
- Quick Book requests are created with `publicName: "In-Room Booking"` (or
  similar) so they're identifiable in the Portal calendar and Kiosk agenda.
- No Meet URL is attached (REQ-18 depends on the Phase 5 auto-provisioning
  trigger, which doesn't exist yet) — `PrivateRequestDetails` is created
  with an empty `meetingUrl`.

## Capabilities

### New Capabilities
- `kiosk-instant-booking`: Defines Quick Book UI/behavior on the Kiosk
  Dashboard, gap detection, auto-confirmation, and In-Room User
  attribution (REQ-16, REQ-17, REQ-21).

### Modified Capabilities
- `data-model`: `Request` gains an optional `bookedVia` field
  (`BookingSource` enum: e.g. `kiosk`) identifying Kiosk-originated
  instant bookings.

## Impact

- `packages/roombooker_core/lib/data/entities/request.dart`: add
  `bookedVia`/`BookingSource` field + codegen.
- `packages/roombooker_kiosk/lib/main.dart` /
  `packages/roombooker_kiosk/lib/agenda_list.dart` (or a new widget): Quick
  Book buttons, gap computation, `addBooking` call.
- `packages/roombooker_portal/lib/ui/`: display "Booked via Kiosk" label
  for requests with `bookedVia == BookingSource.kiosk` (agenda/log views).
- Tests: `packages/roombooker_kiosk/test/`,
  `packages/roombooker_core/test/`, `packages/roombooker_portal/test/`.
- No Firestore rules changes (REQ-20 from `kiosk-access-control` already
  covers this write).
