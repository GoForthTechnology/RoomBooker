# RoomBooker Kiosk Program Plan

This document serves as the master architectural blueprint and requirement specification for the transition of the RoomBooker project into a multi-app ecosystem, culminating in the deployment of the specialized `roombooker_kiosk` application.

## 1. Program Objectives

The goal of this program is to expand RoomBooker from a single user-facing application into an enterprise system comprising a standard portal application and dedicated hardware kiosk terminals.

The Kiosk system SHALL provide an automated, zero-friction "One-Touch Join" experience for meeting rooms, supporting major video conferencing providers, while minimizing hardware cost and maintenance.

## 2. Architectural Decisions & Rationale

### 2.1 Workspace Structure
*   **Decision:** The project SHALL migrate to a Flutter Monorepo Workspace.
*   **Rationale:** The portal and the kiosk share identical data models, authentication handlers, and Firestore repository logic. A monorepo ensures that changes to the core booking logic instantly propagate to both clients, preventing schema drift.
*   **Alternative Considered:** *Separate repositories.* Rejected due to the high overhead of maintaining a shared data package via Git submodules or private pub servers.

### 2.2 Application Separation
*   **Decision:** The system SHALL be divided into two distinct Flutter applications: `roombooker_portal` and `roombooker_kiosk`.
*   **Rationale:** The Kiosk requires aggressive system-level permissions (Accessibility Services, Device Admin) that would trigger intense scrutiny or rejection if submitted to the public Google Play Store. Isolating the Kiosk allows the Portal to remain a standard, unprivileged app.

### 2.3 Automation Engine
*   **Decision:** The "One-Touch Join" automation SHALL be implemented natively in Kotlin using Android's `AccessibilityService`.
*   **Rationale:** Flutter cannot reliably inspect or interact with the UI of external applications (like Google Meet). Native Accessibility Services provide a robust, OS-level mechanism to detect external app foregrounding and execute virtual clicks.
*   **Alternative Considered:** *Deep linking with automated parameters.* Rejected because conferencing apps (specifically Teams and Zoom) often force users into a "Lobby" or "Audio/Video Preview" screen before joining, which cannot be bypassed via deep link parameters alone.

### 2.4 Hardware & Visual Indicators
*   **Decision:** The system SHALL NOT rely on proprietary hardware SDKs or physical tablet LED arrays.
*   **Rationale:** Removing the requirement for physical LEDs allows the use of generic, cheaper enterprise tablets (e.g., Samsung Galaxy Tab Active, StarBoard) provided they support Android 11+ and Power over Ethernet (PoE).
*   **Alternative Considered:** *Mimo Adapt-IQV tablets with side LEDs.* Rejected due to vendor lock-in, higher cost ($550+), and the unnecessary engineering complexity of managing hardware-level platform channels for devices mounted *inside* the room.

### 2.5 Dual-Display Architecture
*   **Decision:** The system SHALL support a Dual-Display configuration using a USB-C Hub with HDMI output.
*   **Rationale:** Enterprise conference rooms require a dedicated "Controller" (the tablet) and a "Stage" (the TV). The tablet must remain functional for room management (extending/ending meetings) even while a video call is active. The system will attempt to route native conferencing apps to the secondary display, with a "Desktop-Spoofed WebView" as a fallback for apps that do not support display routing.
*   **Alternative Considered:** *Single-screen mirroring.* Rejected because it obscures room management controls during active meetings.

### 2.6 Device Provisioning
*   **Decision:** The Kiosk SHALL use a 6-digit "Activation Code" handshake for provisioning.
*   **Rationale:** To avoid entering administrative credentials on wall-mounted hardware, the Portal app will generate short-lived, one-time-use codes that link a physical device to a specific `roomID` and `orgID` via Firestore.
*   **Alternative Considered:** *Direct Admin Login on Kiosk.* Rejected due to security risks and poor user experience (typing long passwords on tablets).

## 3. Strict Requirements

### 3.1 Kiosk Functionality
*   **REQ-01:** The Kiosk SHALL support "One-Touch Join" for **Google Meet**, **Microsoft Teams**, and **Zoom**.
*   **REQ-02:** The Kiosk SHALL automatically bypass "Preview," "Lobby," or "Green Room" screens upon launching a meeting intent.
*   **REQ-03:** The Kiosk SHALL restrict user navigation to the RoomBooker application using Android's `LockTaskMode` (Kiosk Mode).
*   **REQ-04:** The Kiosk UI SHALL prioritize high-contrast, at-a-glance visibility suitable for wall mounting.
*   **REQ-08:** The Kiosk SHALL support a Dual-Display configuration via USB-C HDMI output.
*   **REQ-09:** The Kiosk application SHALL remain visible on the tablet (Primary Display) as a controller while the video conference session is displayed on the TV (Secondary Display) via an integrated WebView or Presentation.
*   **REQ-11:** The Kiosk SHALL provide a 6-digit activation interface for room-to-device provisioning.

### 3.2 System Architecture
*   **REQ-05:** Shared domain logic (Firestore, Models, Auth) SHALL reside in a `roombooker_core` package.
*   **REQ-06:** The `roombooker_portal` application SHALL NOT request Android Accessibility permissions.

### 3.3 Deployment
*   **REQ-07:** The `roombooker_kiosk` application MAY be distributed via MDM (Mobile Device Management) or side-loaded, but SHALL NOT be deployed to the public Google Play Store.

## 4. Execution Phases

To manage risk and maintain a releasable state, the program will be executed in three distinct phases:

*   **Phase 1: The Monorepo Foundation.** Extract shared code into `roombooker_core` and isolate the current app into `roombooker_portal`. (No net-new features).
*   **Phase 2: Native Kiosk Spike.** Scaffold the `roombooker_kiosk` app, establish the Android `AccessibilityService` (Kotlin), and prove the automated "Join" capability.
*   **Phase 3: Dashboard Productization.** Build the Kiosk UI, implement room provisioning logic, and finalize `LockTaskMode`.
