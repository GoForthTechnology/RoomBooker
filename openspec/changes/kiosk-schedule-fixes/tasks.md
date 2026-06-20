## 1. Recurring Booking Expansion

- [x] 1.1 Replace `_bookingService.listRequests(...)` with `_bookingService.getRequestsStream(isAdmin: false, start:, end:, ...)` in `KioskDashboard.initState()` (`packages/roombooker_kiosk/lib/main.dart`)

## 2. Live Clock Ticker

- [x] 2.1 Add `late final Stream<int> _tickerStream` field to `_KioskDashboardState`
- [x] 2.2 Initialize `_tickerStream = Stream.periodic(const Duration(minutes: 1), (i) => i)` in `initState()`
- [x] 2.3 Wrap the outer `StreamBuilder<List<Request>>` in a `StreamBuilder<int>` on `_tickerStream`; capture `final now = DateTime.now()` in the ticker builder so it refreshes every minute

## 3. Today-Only Agenda Filter

- [x] 3.1 In `KioskDashboard.build()`, derive `todayBookings` by filtering `bookings` to entries where `eventStartTime` year/month/day matches `now`
- [x] 3.2 Pass `todayBookings` (not `bookings`) to `AgendaListView` and `QuickBookPanel`

## 4. Verification

- [x] 4.1 Run `flutter analyze` on `roombooker_kiosk` — no issues
- [x] 4.2 Build debug APK and confirm app boots to dashboard without error
- [x] 4.3 Confirm recurring meetings appear at today's occurrence time in the agenda
- [x] 4.4 Confirm no next-day bookings appear in the agenda list
