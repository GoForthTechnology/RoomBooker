## ADDED Requirements

### Requirement: Log Attribution Visibility
The request log widget MUST clearly distinguish between actions taken by the original requester and actions taken by an administrator.

#### Scenario: Display Admin Action
- **WHEN** viewing the request log for a booking that has been approved
- **THEN** the approval entry MUST display the admin's email or name as the actor, not the requester's details.
