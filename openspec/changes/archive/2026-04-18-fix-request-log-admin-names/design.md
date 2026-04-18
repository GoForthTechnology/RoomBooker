## Context

The `RequestLogsWidget` displays a list of actions performed on a booking. Currently, it uses the requester's details (email) from the `PrivateRequestDetails` (accessible via `DecoratedLogEntry.details`) to label every log entry. This results in admin actions being incorrectly attributed to the requester in the UI.

## Goals / Non-Goals

**Goals:**
- Correctly attribute admin-initiated actions (`approve`, `reject`, `delete`, etc.) to the admin in the `RequestLogsWidget`.
- Maintain correct attribution for requester-initiated actions (`create`, `request`).
- Ensure graceful fallback if `adminEmail` is missing (e.g., for legacy logs).

**Non-Goals:**
- Implementing full name resolution for admins (this would require extra Firestore lookups in a already complex stream).
- Modifying the underlying data schema.

## Decisions

### Decision: Conditional Actor Attribution in `RequestLogsWidget`

The `RequestLogsWidget` will be modified to choose the actor's identifier based on the action type.

**Rationale:**
The `DecoratedLogEntry` provides both the original request's `PrivateRequestDetails` (requester info) and the `RequestLogEntry` (which contains `adminEmail`). 

**Logic:**
1. Define a list of "Requester Actions" (e.g., `Action.create`, `Action.request`).
2. If the action is a "Requester Action", use `log.details.email`.
3. If the action is an admin action, check if `log.entry.adminEmail` is present.
   - If present, use `log.entry.adminEmail`.
   - If absent (legacy data), fallback to `log.details.email` with a "(Legacy)" marker or just the email.

**Alternatives Considered:**
- Updating `DecoratedLogEntry` to resolve the admin name: Rejected due to performance concerns and increased complexity in `BookingRepo.decorateLogs`.

## Risks / Trade-offs

- **[Risk]** Missing `adminEmail` in legacy logs.
  - **Mitigation:** Fallback to requester email with clear indication or just show the available email.
- **[Risk]** Inconsistent UI if some logs show names and others show emails.
  - **Mitigation:** Stick to emails for now as they are guaranteed to be in both `PrivateRequestDetails` and `adminEmail`.
