## Why

The Kiosk Dashboard currently only shows the room's *current* status
(AVAILABLE/OCCUPIED) plus the in-progress meeting's title and join button,
backed by a narrow `-1h`/`+4h` booking query. Per the Program Plan's "In-Room
Tactical Hub" vision, users standing at the Kiosk need to see the whole day's
schedule at a glance (REQ-04, REQ-15) so they can plan around upcoming
meetings without leaving the room. Phase 4b adds this scrollable daily agenda
and has no dependency on the Phase 4a/4c work that just landed.

## What Changes

- Add a new `kiosk-dashboard` capability spec covering the Kiosk Dashboard's
  status display and daily agenda requirements (REQ-04 Tactical Information
  Density, REQ-15 Scrollable Daily Agenda).
- Widen the Kiosk's booking query from `now-1h`/`now+4h` to the full current
  day (local midnight to midnight) for the assigned room.
- Add a scrollable agenda list to the Kiosk Dashboard showing every confirmed
  booking for the day (time range + title), ordered chronologically, with the
  current/in-progress booking visually highlighted.
- Keep the existing hero AVAILABLE/OCCUPIED status, room name, and "JOIN
  MEETING" button for the current booking; the agenda list is added below/
  alongside them, not a replacement.
- Re-derive "current booking" from the widened daily booking set instead of
  the old narrow-window stream.

## Capabilities

### New Capabilities
- `kiosk-dashboard`: Defines the Kiosk Dashboard's room-status display and
  scrollable daily agenda requirements (REQ-04, REQ-15).

### Modified Capabilities
(none — no existing spec currently documents Kiosk Dashboard behavior)

## Impact

- `packages/roombooker_kiosk/lib/main.dart`: `_KioskDashboardState`'s booking
  stream/query and the dashboard body layout.
- New widget(s) for the agenda list (likely a new file under
  `packages/roombooker_kiosk/lib/`).
- `packages/roombooker_kiosk/test/`: new/updated widget tests for the agenda
  list and the widened query.
- No changes to `roombooker_core` data model, repos, or Firestore rules.
