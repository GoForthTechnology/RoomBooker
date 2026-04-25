## Why

Firebase AppCheck (ReCAPTCHA) is a critical security feature enforced for this application. Currently, AppCheck initialization failures are not explicitly handled, which can lead to unhandled exceptions. Since rejections are expected for abusive traffic, the application must identify these cases and inform the user that they have been flagged, rather than allowing them to proceed or masking the security failure.

## What Changes

- Wrap Firebase AppCheck activation in a try-catch block specifically to identify and handle rejections.
- Implement an "Abusive Traffic Detected" UI state that is shown when AppCheck fails to validate the client.
- Ensure the initialization sequence stops and displays this security notice when AppCheck enforcement fails, preventing unauthorized access to the application.

## Capabilities

### New Capabilities
- none

### Modified Capabilities
- `architecture`: Update initialization flow to enforce critical security checks and provide explicit user feedback for security rejections.

## Impact

- `lib/main.dart`: Changes to `_initialize` to handle AppCheck rejections.
- User Experience: Users flagged by ReCAPTCHA will see a clear security-related message.
