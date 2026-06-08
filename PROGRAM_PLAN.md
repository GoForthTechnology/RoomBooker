# RoomBooker Kiosk Program Plan

This document serves as the master architectural blueprint and requirement specification for the transition of the RoomBooker project into a multi-app ecosystem, culminating in the deployment of the specialized `roombooker_kiosk` application.

## 1. Program Objectives

The goal of this program is to expand RoomBooker from a single user-facing application into an enterprise system comprising a standard portal application and dedicated hardware kiosk terminals.

**The Vision: From Signage to Hub**
The Kiosk system is transitioning from a passive "Hallway Sign" into an active "In-Room Tactical Hub." It SHALL provide a high-utility, zero-friction interface for room users to:
1.  **Orchestrate Meetings**: One-touch join for synchronized dual-display video conferencing.
2.  **Manage Time**: View the daily room agenda at a tactical distance.
3.  **Claim Space**: Instantly book available time slots directly from the wall-mounted hardware.

## 2. Architectural Decisions & Rationale

### 2.1 Workspace Structure
*   **Decision:** The project SHALL migrate to a Flutter Monorepo Workspace. [DONE]
*   **Rationale:** The portal and the kiosk share identical data models, authentication handlers, and Firestore repository logic.

### 2.2 Application Separation
*   **Decision:** The system SHALL be divided into two distinct Flutter applications: `roombooker_portal` and `roombooker_kiosk`. [DONE]

### 2.3 Automation Engine
*   **Decision:** The "One-Touch Join" automation SHALL be implemented natively in Kotlin using Android's `AccessibilityService`. [DONE]

### 2.4 Hardware & Visual Indicators
*   **Decision:** The system SHALL NOT rely on proprietary hardware SDKs or physical tablet LED arrays. [DONE]

### 2.5 Dual-Display Architecture
*   **Decision:** The system SHALL support a Dual-Display configuration using a USB-C Hub with HDMI output. [DONE]

### 2.6 Device Provisioning
*   **Decision:** The Kiosk SHALL use a 6-digit "Activation Code" handshake for provisioning. [DONE]

### 2.7 System Identity (The "In-Room User")
*   **Decision:** Organizations SHALL have a dedicated "System User" identity for Kiosk attribution.
*   **Rationale:** To facilitate instant "In-Room Bookings" without requiring personal logins on shared hardware, the Kiosk will act as a virtual administrator. This ensures accountability (attributed to 'In-Room Hub') while maintaining speed.

## 3. Strict Requirements

### 3.1 Kiosk Functionality (The Tactical Hub)
*   **REQ-01:** The Kiosk SHALL support "One-Touch Join" for **Google Meet**, **Microsoft Teams**, and **Zoom**. [DONE]
*   **REQ-02:** The Kiosk SHALL automatically bypass "Preview," "Lobby," or "Green Room" screens. [DONE]
*   **REQ-03:** The Kiosk SHALL restrict user navigation using Android's `LockTaskMode`. [DONE]
*   **REQ-04:** The Kiosk UI SHALL prioritize **Tactical Information Density**, optimized for use from 1-3 feet (arm's length).
*   **REQ-15:** The Kiosk SHALL display a **Scrollable Daily Agenda**, showing all confirmed bookings for the current room.
*   **REQ-16:** The Kiosk SHALL support **Instant Room Claiming** via "Quick Book" buttons (15m, 30m, 60m) during available gaps.
*   **REQ-17:** Instant bookings created via the Kiosk SHALL be attributed to the organization's "In-Room User" and auto-confirmed.

### 3.2 Hardware & Orchestration
*   **REQ-08:** The Kiosk SHALL support a Dual-Display configuration via USB-C HDMI output. [DONE]
*   **REQ-09:** The Kiosk application SHALL remain visible on the tablet (Primary Display) as a controller while the video conference session is displayed on the TV (Secondary Display). [DONE]
*   **REQ-11:** The Kiosk SHALL provide a 6-digit activation interface for room-to-device provisioning. [DONE]

### 3.3 Link Privacy & Security
*   **REQ-12:** Video conference links MUST be stored in `PrivateRequestDetails` to prevent unauthorized access from public calendar views.
*   **REQ-13:** The Kiosk application SHALL be granted temporary read access to the `PrivateRequestDetails` for the active meeting in its assigned room.

### 3.4 Automation & Integration
*   **REQ-14:** The system SHALL support auto-provisioning of Google Meet links via Workspace API upon Admin confirmation.
*   **REQ-18:** Instant bookings created on the Kiosk SHALL automatically trigger the auto-provisioning engine to attach a Meet URL.

## 4. Execution Phases

### Phase 1: The Monorepo Foundation [DONE]
Extract shared code into `roombooker_core` and isolate `roombooker_portal`.

### Phase 2: Native Kiosk Spike [DONE]
Establish the Android `AccessibilityService` (Kotlin) and prove automated "Join."

### Phase 3: Dashboard Productization [DONE]
Build high-contrast UI, 6-digit provisioning, and basic Dual-Display routing.

### Phase 4: Tactical Hub & Secure Orchestration [IN PROGRESS]
*   **Agenda View**: Refactor Dashboard to show full daily agenda.
*   **Instant Booking**: Implement "Quick Book" buttons and "In-Room User" identity.
*   **Privacy Guard**: Move meeting URLs to `PrivateRequestDetails`.
*   **Scoped Access**: Implement Firestore rules for room-specific Kiosk access.

### Phase 5: Advanced Automation & Deployment
*   **Auto-Provisioning**: Cloud Functions for Google Workspace integration (Meet link generation).
*   **Proactive Feedback**: "Ending Soon" notifications and "Extend Meeting" controls.
*   **Ops Monitoring**: Remote heartbeat and hardware status reporting.
