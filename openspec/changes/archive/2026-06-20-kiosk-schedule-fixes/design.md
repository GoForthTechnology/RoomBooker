## Context

`KioskDashboard` in `packages/roombooker_kiosk/lib/main.dart` drives the room status display and agenda list. Its booking data came from `BookingService.listRequests`, a raw Firestore passthrough that queries confirmed bookings by time window but does **not** call `Request.expand()`. Recurring bookings are stored once with their original `eventStartTime`; without expansion they appear at the wrong time (or not at all) in the agenda.

`DateTime.now()` was captured inside the `StreamBuilder.builder` callback, which only fires when Firestore emits. A meeting transitioning from upcoming → current → past triggered no Firestore write, so the AVAILABLE/OCCUPIED banner and current-booking highlight could be arbitrarily stale.

`BookingRepo.listRequests` adds a +1 hour DST buffer to the end-time bound, and `getRequestsStream` expands recurring patterns up to that bound. This can yield bookings whose `eventStartTime` is in the next calendar day.

## Goals / Non-Goals

**Goals:**
- Recurring bookings appear at their actual today-occurrence times in the agenda list.
- AVAILABLE/OCCUPIED status and current-booking highlight update at least every minute.
- `AgendaListView` shows only same-calendar-day bookings.

**Non-Goals:**
- Changing `BookingRepo` query logic or the DST hack.
- Supporting multi-day booking display on the kiosk.
- Rolling the booking window over at midnight without a restart.

## Decisions

### Use `getRequestsStream` instead of `listRequests`

`BookingService` exposes two stream methods:
- `listRequests` — raw passthrough, no `expand()` call.
- `getRequestsStream(isAdmin: false)` — calls `Request.expand()` on every result, projecting recurring templates into per-occurrence instances within the query window.

The kiosk is not an admin context; `isAdmin: false` skips private-detail enrichment, keeping the stream lightweight. No new abstraction is needed.

### Ticker via `Stream.periodic`

A `Stream.periodic(Duration(minutes: 1), (i) => i)` is created in `initState` and stored as `_tickerStream`. The outer `StreamBuilder` listens to it; `DateTime.now()` is captured in that builder's callback. This guarantees `now` is at most 1 minute stale regardless of Firestore activity. The computation argument `(i) => i` is required because `Stream<int>` is non-nullable in null-safe Dart — omitting it throws `ArgumentError` at runtime.

### Filter in `build()` before passing to widgets

Same-day filtering is a presentation concern, not a data concern. A single `.where` filter applied to `bookings` before it reaches `AgendaListView` and `QuickBookPanel` is the smallest possible change and keeps the repo/service layer untouched.

```dart
final todayBookings = bookings
    .where((b) =>
        b.eventStartTime.year == now.year &&
        b.eventStartTime.month == now.month &&
        b.eventStartTime.day == now.day)
    .toList();
```

## Risks / Trade-offs

- **`getRequestsStream` uses `switchMap`** — every time the underlying Firestore snapshot changes it re-expands. For a single room's bookings this is negligible, but worth noting.
- **1-minute ticker granularity** — a meeting that starts at :00 may not reflect in the UI until :01. Acceptable for a room display; sub-minute precision is not required.
- **Midnight rollover not handled** — `startOfDay` is fixed at widget init. A kiosk running continuously past midnight will show the previous day's window until restarted. Out of scope for this change.
