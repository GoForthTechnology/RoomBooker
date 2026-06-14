## 1. Verify spec accuracy against source

- [x] 1.1 Cross-check the "Request Stream Expansion and Enrichment"
      requirement against `getRequestsStream` in
      `packages/roombooker_core/lib/data/services/booking_service.dart`; fix
      any inaccuracies found.
- [x] 1.2 Cross-check the "Request Validation" requirement against
      `validateRequest`, `submitBookingRequest`, `updateBooking`, and
      `addBooking`; fix any inaccuracies found.
- [x] 1.3 Cross-check the "Overlap Detection" requirement against
      `findOverlappingBookings`, `_findOverlapsForList`, and
      `_doRequestsOverlap`; fix any inaccuracies found.
- [x] 1.4 Cross-check the "Blackout Window Derivation" requirement against
      `listBlackoutWindows` and `_defaultBlackoutWindows`; fix any
      inaccuracies found.
- [x] 1.5 Cross-check the "Pass-Through Write and Read Delegation"
      requirement against the remaining `BookingService` methods; fix any
      inaccuracies found.

## 2. Validation

- [x] 2.1 Run `openspec validate spec-booking-service --strict` and confirm
      the change's spec delta is valid.
- [x] 2.2 Confirm no code or test files were modified (this change is
      documentation-only).
