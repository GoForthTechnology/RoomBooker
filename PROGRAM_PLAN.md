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

### 2.8 Kiosk Device Identity & Scoped Access
*   **Decision:** The Kiosk SHALL authenticate to Firebase using a room-scoped credential issued during the provisioning handshake, rather than operating as an anonymous/unauthenticated client.
*   **Rationale:** Secure, room-scoped read access to `PrivateRequestDetails` (REQ-13) and the ability to write auto-confirmed bookings as the "In-Room User" (REQ-17) both require Firestore security rules to identify the requesting Kiosk and its assigned room. The current open `kiosks/{deviceID}` rule and org-wide `isAdmin()` check cannot support this. This decision is a **prerequisite** for the rest of Phase 4.

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
*   **REQ-12:** Video conference links MUST be stored in `PrivateRequestDetails` to prevent unauthorized access from public calendar views. Existing `confirmed-requests` documents with a public `meetingUrl` field MUST be migrated (or read-compatible during a transition window) so no links are lost.
*   **REQ-13:** The Kiosk application SHALL be granted read access to `PrivateRequestDetails`, scoped to its assigned room, for the active meeting in that room.

### 3.4 Automation & Integration
*   **REQ-14:** The system SHALL support auto-provisioning of Google Meet links via Workspace API upon Admin confirmation.
*   **REQ-18:** Instant bookings created on the Kiosk SHALL automatically trigger the auto-provisioning engine to attach a Meet URL. *(Depends on the Phase 5 auto-provisioning engine; until that exists, instant bookings are created without a Meet URL — see Phase 4d.)*

### 3.5 Kiosk Identity & Access Control
*   **REQ-19:** During provisioning, the Kiosk SHALL be issued a room-scoped Firebase Auth credential (e.g. a custom token/claims containing `orgID` and `roomID`), replacing the current anonymous/unauthenticated client.
*   **REQ-20:** Firestore security rules SHALL grant a Kiosk read access to `PrivateRequestDetails` and write access to `confirmed-requests` only for documents belonging to its assigned `roomID`.
*   **REQ-21:** The "In-Room User" (see 2.7) SHALL be represented as a concrete, attributable identity (e.g. an `Organization.systemUserID` or dedicated admin-equivalent record) usable to attribute Kiosk-originated bookings.

## 4. Execution Phases

### Phase 1: The Monorepo Foundation [DONE]
Extract shared code into `roombooker_core` and isolate `roombooker_portal`.

### Phase 2: Native Kiosk Spike [DONE]
Establish the Android `AccessibilityService` (Kotlin) and prove automated "Join."

### Phase 3: Dashboard Productization [DONE]
Build high-contrast UI, 6-digit provisioning, and basic Dual-Display routing.

### Phase 4: Tactical Hub & Secure Orchestration [IN PROGRESS]
This phase is split into sequenced sub-changes. 4a and 4c are
prerequisites for 4d; 4b can proceed in parallel with 4a/4c.

*   **4a. Privacy Guard** [DONE]: Move `meetingUrl` from `Request`
    to `PrivateRequestDetails` (REQ-12), including a migration/compat
    plan for existing documents and updates to the Portal request
    editor and Kiosk dashboard.
*   **4b. Agenda View** [NOT STARTED]: Refactor the Kiosk Dashboard to
    show a scrollable daily agenda for the assigned room (REQ-04,
    REQ-15). No auth dependency — can be done independently.
*   **4c. Kiosk Device Identity & Scoped Access** [DONE]:
    Issue a room-scoped Firebase Auth credential during provisioning
    (REQ-19), define the "In-Room User" identity (REQ-21), and add
    Firestore rules granting room-scoped access to
    `PrivateRequestDetails` and `confirmed-requests` (REQ-13, REQ-20).
    Foundational prerequisite for 4d. Also removes the unused
    `KioskIdentity`/`registerKiosk`/`kiosks/{deviceID}` scaffolding
    (dead code with an overly-open Firestore rule).
    *   **Future follow-up (not in scope for 4c):** the
        `kiosk-grants/{uid}` doc introduced here stores enough metadata
        (`deviceID`, `createdAt`) to let the Portal show, per room,
        whether a Kiosk is currently attached (and since when). This
        should become a small Portal admin-UI change in a later
        change/phase — likely alongside Phase 5's Ops Monitoring work.
*   **4d. Instant Booking ("Quick Book")** [NOT STARTED]: Implement
    gap/conflict detection and "Quick Book" buttons (15m/30m/60m)
    that create auto-confirmed bookings attributed to the In-Room User
    (REQ-16, REQ-17), using the identity/rules from 4c. Created without
    a Meet URL until Phase 5's auto-provisioning trigger exists (REQ-18).

### Phase 5: Advanced Automation & Deployment
*   **Auto-Provisioning**: Cloud Functions for Google Workspace integration
    (Meet link generation), including the trigger that fulfills REQ-18
    for Kiosk-originated instant bookings.
*   **Proactive Feedback**: "Ending Soon" notifications and "Extend Meeting" controls.
*   **Ops Monitoring**: Remote heartbeat and hardware status reporting.
