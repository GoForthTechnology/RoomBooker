## Context

`_KioskDashboardState` (`packages/roombooker_kiosk/lib/main.dart`) currently
subscribes to `BookingService.listRequests` with a `now - 1h` / `now + 4h`
window, filtered to confirmed bookings for the assigned room. It uses that
list only to find the single "current" booking (start <= now < end) and
derive AVAILABLE/OCCUPIED. There is no view of later meetings.

Phase 4b (REQ-04, REQ-15) asks for a scrollable daily agenda so a user
standing at the Kiosk can see the room's full schedule for "today" at a
glance, while still surfacing the current meeting and Join button
prominently.

## Goals / Non-Goals

**Goals:**
- Show all confirmed bookings for the assigned room for the current local
  day in a scrollable list.
- Keep the existing hero status (AVAILABLE/OCCUPIED, room name, current
  meeting title + Join button) working from the same data set.
- Visually distinguish the in-progress booking in the agenda list.
- Tactical Information Density (REQ-04): legible from 1-3 feet — large
  fonts, high contrast, minimal chrome.

**Non-Goals:**
- No changes to auth, Firestore rules, or `roombooker_core` data
  model/repos — this is a Kiosk UI + query-window change only.
- No "Quick Book" / instant booking UI (that's Phase 4d).
- No cross-day agenda (e.g. "tomorrow" view) — "today" only, per REQ-15.
- No changes to the diagnostic/system-log panel.

## Decisions

### 1. Widen the query window to the local calendar day
Replace the `now - 1h` / `now + 4h` window with
`[startOfDay(now), startOfDay(now) + 1 day)` (local time), still filtered to
`includeRoomIDs: {roomID}` and `includeStatuses: {RequestStatus.confirmed}`.
This is the minimal change needed to get "today's agenda" and keeps using
`BookingService.listRequests` (no new repo/service methods).

Alternative considered: stream a rolling window (e.g. now-1h to
end-of-day) to reduce reads. Rejected — a full-day query is simple, matches
REQ-15's "daily agenda" wording exactly, and booking volume per room per day
is small enough that this isn't a performance concern.

### 2. New `AgendaListView` widget in its own file
Add `packages/roombooker_kiosk/lib/agenda_list.dart` containing a stateless
`AgendaListView` widget that takes the day's `List<Request>` (already
fetched by `_KioskDashboardState`) plus `now`, sorts by `eventStartTime`, and
renders a `ListView` of rows (time range + `publicName`/"Private Meeting").
The row matching the current booking (same logic as today's
start<=now<end check) is highlighted (e.g. accent border/background).

Keeping this as a separate small widget file (vs. inlining into
`main.dart`) follows the existing pattern of `stage_ui.dart` /
`webview_stage.dart` as separately-testable widgets, and keeps
`_KioskDashboardState.build` from growing further.

### 3. Layout: hero status + agenda list, both scrollable region
The existing hero column (room name, AVAILABLE/OCCUPIED, current meeting +
Join button) stays at the top. `AgendaListView` is added below it, inside
the same scrollable area, with a fixed-ish minimum height (e.g.
`Expanded`/`SizedBox` inside the existing `Column`) so it remains visible
without the page becoming a single giant scroll dominated by the hero
section. Exact sizing is a layout/implementation detail to be tuned during
apply, not a spec requirement.

### 4. Reuse a single day-scoped stream for both hero and agenda
`_bookingsStream` is redefined to the full-day query; `currentBooking` is
derived from it as today, and the same list is passed to `AgendaListView`.
No second Firestore subscription is introduced.

## Risks / Trade-offs

- **[Risk]** A room with many bookings in a day could make the agenda list
  long. → It's already scrollable (REQ-15 explicitly calls for
  "scrollable"), so this is the intended behavior, not a bug.
- **[Risk]** "Local day" boundaries depend on device timezone/clock. →
  Existing code already uses `DateTime.now()` for "current booking"
  detection, so this introduces no new dependency; device clock accuracy is
  out of scope for this change.
- **[Trade-off]** Full-day query reads slightly more documents than the old
  ±window, but per-room daily booking counts are small (see Non-Goals) so
  this is acceptable.

## Migration Plan

No data migration. This is a client-only change to
`packages/roombooker_kiosk`; rollout is via the existing Kiosk APK
distribution (Firebase App Distribution / Play Internal Track per
`CLAUDE.md` CI rules). No rollback concerns beyond shipping a new build.

## Open Questions

None — scope is bounded to the Kiosk dashboard UI and its booking query.
