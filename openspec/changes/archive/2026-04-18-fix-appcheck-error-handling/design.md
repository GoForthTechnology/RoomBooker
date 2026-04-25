## Context

The application relies on Firebase AppCheck for security enforcement. ReCAPTCHA rejections on Web are the primary mechanism for identifying and blocking abusive traffic. The current initialization logic does not distinguish between transient errors and security-driven rejections, and users want to track rejection rates without cluttering Sentry with unhandled exceptions.

## Goals / Non-Goals

**Goals:**
- Enforce AppCheck as a mandatory step in the initialization sequence.
- Distinguish between transient initialization errors and security rejections.
- Notify users when they are flagged as abusive traffic.
- **Track the rate of rejections using Sentry Metrics (non-exception events).**

**Non-Goals:**
- Allowing the user to bypass AppCheck if it fails to activate for security reasons.

## Decisions

### 1. Mandatory AppCheck Activation
- **Decision**: Treat AppCheck activation as a blocking, mandatory step. 
- **Rationale**: Since it is enforced, any failure to validate must prevent access to the app's internal state.

### 2. Abusive Traffic UI
- **Decision**: Define a specific error state for `AppCheckException` or relevant ReCAPTCHA errors that indicates "Access Denied: Abusive Traffic Detected".
- **Rationale**: Per user requirement, we must explicitly notify flagged users rather than retrying or ignoring.

### 3. Sentry Rejection Tracking
- **Decision**: Use `Sentry.captureMessage` with `SentryLevel.warning` and specific tags (`security: abusive_traffic`) to record rejections.
- **Rationale**: This allows the team to monitor rejection rates via the Sentry Issues or Discover tabs without triggering "Unhandled Exception" alerts or masking legitimate crashes. Custom metrics were considered but `captureMessage` with tags provides immediate visibility in the current SDK configuration.

## Risks / Trade-offs

- **[Risk]** False positives (legitimate users flagged) -> **Mitigation**: This is handled by ReCAPTCHA's internal logic and the Firebase Console configuration.
- **[Risk]** Missing metrics -> **Mitigation**: Ensure Sentry is initialized *before* AppCheck so that early metrics are captured.
