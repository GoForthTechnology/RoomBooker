## Why

The request log on the settings page currently attributes all actions—including admin-only operations like approvals, rejections, and deletions—to the original requester. This happens because the log widget defaults to displaying the email from the `PrivateRequestDetails` associated with the request, rather than the actor identified in the log entry itself. This makes it difficult to track who actually performed an action.

## What Changes

- **Modified Log Display Logic**: The request log widget will be updated to display the `adminEmail` from the log entry for admin-initiated actions (`approve`, `reject`, `delete`, `revisit`, `endRecurring`, `ignoreOverlaps`).
- **Improved Actor Attribution**: For `create` and `request` actions, the requester's email from `PrivateRequestDetails` will continue to be shown.
- **Admin Name Resolution (Optional/Future)**: While `adminEmail` is currently captured, the system should ideally show the admin's display name if a matching `UserProfile` exists. For this fix, we will focus on at least showing the `adminEmail` correctly.

## Capabilities

### Modified Capabilities
- `product`: Update requirements to ensure accurate attribution of actions in the request log.
- `ui-ux`: Define how the request log should distinguish between requester actions and admin actions.

## Impact

- `lib/ui/widgets/request_logs_widget.dart`: Primary UI change to show the correct actor.
- `lib/data/entities/log_entry.dart`: The `RequestLogEntry` already has `adminEmail`, but we may want to ensure it's easily accessible in the UI.
- `lib/data/repos/booking_repo.dart`: Ensure all admin actions correctly populate the `adminEmail` field during logging.
