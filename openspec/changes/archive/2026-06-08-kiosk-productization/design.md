## Context

This design transitions the RoomBooker Kiosk from a technical spike (V5.8) into a production-ready enterprise product. The primary technical challenges are secure room-to-device mapping (Provisioning) and managing two distinct UI contexts simultaneously (Dual-Display Orchestration).

## Goals / Non-Goals

**Goals:**
- Implement a zero-config 6-digit activation handshake.
- Develop a high-contrast, state-aware Dashboard for the Tablet (Controller).
- Implement the Stage UI for the TV (Secondary Display).
- Orchestrate meeting launches between Native and WebView based on display support.
- Ensure the Kiosk remains locked and operational across reboots.

**Non-Goals:**
- Auto-provisioning of Meet links (Phase 5).
- Full "Quick Book" logic (Phase 4).
- User authentication on the Kiosk (only Activation Codes).

## Decisions

### 1. Provisioning: The Firestore Handshake
- **Decision**: Use a temporary `provisioning_codes` collection in Firestore.
- **Rationale**: Allows the Portal app to "authorize" a physical device for a specific room without sharing Admin credentials.
- **Implementation**: 
    1. Portal writes `{ code: "123456", roomId: "...", orgId: "...", expires: timestamp }`.
    2. Kiosk reads this document, saves IDs to `flutter_secure_storage`, and deletes the code.

### 2. Dual-Display Logic: Controller and Stage
- **Decision**: Use the `presentation_displays` package to manage the secondary display context.
- **Rationale**: Provides a standard Flutter way to render a separate widget tree on an external display (HDMI/USB-C Hub).
- **Mapping**:
    - **Primary (Tablet)**: `DashboardControllerWidget` (Mute, End Call, Extend).
    - **Secondary (TV)**: `MeetingStageWidget` (WebView or Room Info).

### 3. Meeting Orchestration: Native vs. WebView
- **Decision**: Primary path is Native Intent with `setLaunchDisplayId`. Fallback is `InAppWebView` with Desktop User-Agent.
- **Rationale**: Native apps provide better performance, but many Android apps (like Teams) do not support being "forced" to a secondary display. WebView allows us to "own" the secondary display context entirely.
- **Automation**: Use JavaScript Injection in the WebView fallback to auto-click "Join" buttons, mirroring the logic of the `AccessibilityService`.

### 4. Persistence: Boot-Aware Lockdown
- **Decision**: Implement a `BroadcastReceiver` for `ACTION_BOOT_COMPLETED`.
- **Rationale**: Ensures the tablet automatically re-launches RoomBooker and enters `LockTaskMode` after a power failure.

### 5. Metadata Synchronization: IDs as Pointers
- **Decision**: The Kiosk SHALL NOT persist human-readable names (Room Name, Org Name) in local storage.
- **Rationale**: To ensure the UI always reflects the "Source of Truth" in the Portal (handling renames), the Kiosk will use provisioned IDs to establish live Firestore streams for all metadata.

## Risks / Trade-offs

- **[Risk] Secure Node Detection in WebViews** → **Mitigation**: Implement a robust JS-injection library that searches for common Conferencing DOM selectors.
- **[Risk] Display Discovery Latency** → **Mitigation**: Show a "TV Not Connected" warning on the tablet if the USB-C Hub is unplugged.
- **[Risk] Firestore Rule Bloat** → **Mitigation**: Use a specific `kiosks` sub-collection under `organizations` to manage device identities.
