## 1. UI Updates

- [x] 1.1 Modify `RequestLogsWidget._logView` in `lib/ui/widgets/request_logs_widget.dart` to determine the actor based on the action type.
- [x] 1.2 Implement logic to show `log.entry.adminEmail` for admin actions (`approve`, `reject`, `delete`, `revisit`, `endRecurring`, `ignoreOverlaps`).
- [x] 1.3 Maintain `log.details.email` for requester actions (`create`, `request`).
- [x] 1.4 Add a fallback to `log.details.email` if `adminEmail` is missing for admin actions.

## 2. Verification & Testing

- [x] 2.1 Manually verify the fix by checking the request log for a newly approved booking.
- [x] 2.2 Verify that creation logs still show the requester's email.
- [x] 2.3 Verify that rejection and deletion logs show the admin's email.
