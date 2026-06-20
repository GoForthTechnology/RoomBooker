## Why

The kiosk dashboard's schedule view displayed incorrect data for recurring bookings (showing the original template date rather than today's occurrence) and its AVAILABLE/OCCUPIED status only updated when Firestore emitted new data — not when time passed. Additionally, the agenda list could surface bookings from the following day, requiring unnecessary day disambiguation.

## What Changes

- **Recurring booking expansion**: Replace the raw `BookingService.listRequests` passthrough with `BookingService.getRequestsStream(isAdmin: false)` so recurring bookings are expanded into their actual occurrence times for today.
- **Live clock for status**: Add a `Stream.periodic(1 minute)` ticker so `DateTime.now()` is refreshed on a timer, keeping the AVAILABLE/OCCUPIED banner and current-booking highlight current without depending on Firestore activity.
- **Today-only agenda filter**: Filter the bookings list passed to `AgendaListView` and `QuickBookPanel` to only include entries whose `eventStartTime` falls on the current calendar day, preventing next-day occurrences (surfaced by the DST +1h query window or recurring expansion) from appearing.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `kiosk-dashboard`: Agenda list now shows only same-day bookings with correct occurrence times for recurring events; room status refreshes on a 1-minute timer.

## Impact

- `packages/roombooker_kiosk/lib/main.dart`: `KioskDashboard` state and build method.
- No changes to `roombooker_core`, Firestore schema, or other packages.
