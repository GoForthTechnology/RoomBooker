## Why

To support automated room management, the Kiosk application must be able to programmatically "join" meetings in third-party conferencing apps (Google Meet, Microsoft Teams, Zoom) to eliminate the "Green Room" friction for users in the room. Since Flutter cannot interact with external app UIs, we must implement a native Android Accessibility Service to perform these virtual clicks. This spike aims to prove this capability and establish the Kiosk scaffolding.

## What Changes

- **Kiosk Scaffolding**: Create `packages/roombooker_kiosk` as a new Flutter application in the workspace.
- **Native Service Implementation**: Create `MeetAutomatorService.kt` (Android Accessibility Service) in the Kiosk package.
- **Intent Orchestration**: Implement a minimal Flutter UI in the Kiosk app to launch meeting URLs via Android Intents.
- **Device Management Config**: Add XML configurations for `DeviceAdmin` and `AccessibilityService` to the Kiosk's Android module.
- **Kiosk Mode Integration**: Integrate the `kiosk_mode` package to test basic app pinning (`LockTaskMode`).

## Capabilities

### New Capabilities
- `kiosk-automation`: System-level automation for joining external video conferences.
- `kiosk-mode`: Restriction of device usage to the RoomBooker Kiosk application.

### Modified Capabilities
- `architecture`: Expansion of the workspace to include a second application target (`roombooker_kiosk`).

## Impact

- **Permissions**: The Kiosk app will require `BIND_ACCESSIBILITY_SERVICE` and `BIND_DEVICE_ADMIN` permissions.
- **Codebase**: Introduction of native Kotlin code into the `roombooker_kiosk` package.
- **Deployment**: The Kiosk app will have a different application ID and signing requirements than the Portal app.
