## Why

To transform the Kiosk technical spike into a production-ready enterprise terminal that can be securely provisioned to specific rooms and support high-contrast dual-display meeting management. This ensures a consistent, secure, and zero-friction experience for in-room meeting management while maintaining a functional controller for room orchestration.

## What Changes

- **Provisioning Flow**: Implement a 6-digit "Activation Code" handshake to link new hardware to specific rooms without entering administrative credentials on the terminal.
- **Dual-Display Controller**: Develop the high-contrast Dashboard UI for the tablet (Primary Display) that remains visible as a controller even when a meeting is active.
- **TV Stage Integration**: Implement the "Stage" UI for the TV (Secondary Display) to render the video conference session or room status information via HDMI/WebView.
- **Real-time Synchronization**: Connect the Kiosk to live Firestore streams via `BookingService` to drive "Meeting Now" and "Up Next" states.
- **Enterprise Lockdown**: Finalize `LockTaskMode` and `DeviceAdmin` settings to ensure the terminal remains a dedicated instrument across reboots and power cycles.

## Capabilities

### New Capabilities
- `kiosk-provisioning`: Implementation of the activation handshake and local device identity persistence.
- `dual-display-orchestration`: Logic for managing separate UI contexts for the Controller (Tablet) and Stage (TV).

### Modified Capabilities
- `kiosk-automation`: Refining the "One-Touch Join" logic to operate within the productized Dashboard and support dual-display routing.
- `ui-ux`: Defining specific design requirements for high-visibility, wall-mounted kiosk interfaces.

## Impact

- **Kiosk Package**: Significant expansion of the `roombooker_kiosk` Flutter and Kotlin modules.
- **Core Package**: Introduction of provisioning entities and potentially a "Service Account" identity model for Kiosks.
- **Firestore**: New collections/rules for provisioning codes and device tracking.
- **Device Lifecycle**: Requirements for `RECEIVE_BOOT_COMPLETED` to ensure the Kiosk re-locks after power failures.
