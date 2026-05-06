## Why

Users are currently unable to reschedule individual instances of a recurring event series. When an instance is moved to a new date, the system incorrectly renders the original instance on the original date and fails to show the rescheduled instance on the new date.

## What Changes

- Update `BookingRepo` to correctly use the original instance date as the key for recurrence overrides.
- Fix inconsistency in `deleteBooking` where it used `eventEndTime` instead of `eventStartTime` for override indexing.
- Ensure that rescheduling an instance correctly removes it from the original recurring slot and places it in the new slot.

## Capabilities

### New Capabilities
- `instance-rescheduling`: The ability to move a single instance of a recurring series to a different date and time while maintaining the rest of the series.

### Modified Capabilities
- `product`: Updated to ensure the "Prevent Double-Booking" requirement correctly accounts for rescheduled instances.

## Impact

- `BookingRepo`: Modified logic in `updateBooking` and `deleteBooking`.
- `Request`: Potential impact on `expand` and `_generateDates` if data structure changes are required (though mostly handled at repo level).
- `BookingService`: No direct logic changes, but will facilitate the updated repo methods.
