# UI Conventions Specification: Room Booker Portal

## Purpose
This document defines binding UI/UX conventions for the Portal app
(`roombooker_portal`). All new Portal features and any changes to existing
Portal screens MUST comply with these rules before implementation begins.
The conventions are written for a **mobile-first Flutter web/mobile app**
targeting a minimum viewport width of 375 dp.

## [UI-CONV-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119.

---

## [UI-CONV-001] ListTile Trailing Budget

### Requirement
A `ListTile.trailing` (or the equivalent trailing area of an
`ExpansionTile`) MUST contain at most **one** interactive element
(e.g. `IconButton`, `TextButton`).

### Rationale
Flutter's `ListTile` reserves approximately 72 dp for the trailing slot.
A single 48 dp `IconButton` fits comfortably. Two buttons (96 dp) push
into the title/subtitle area on a 375 dp viewport; three (144 dp)
guarantee a layout overflow.

### Allowed
```dart
// Single action — always OK
trailing: IconButton(icon: Icon(Icons.edit), onPressed: ...),
```

### Not Allowed
```dart
// Two or more actions in trailing — MUST be refactored
trailing: Row(children: [
  IconButton(icon: Icon(Icons.edit), ...),
  IconButton(icon: Icon(Icons.delete), ...),
]),
```

### Remediation
When a list item needs more than one action, use one of:
- A single **"more" icon button** (`Icons.more_vert`) that opens a
  `PopupMenuButton` listing all actions.
- A single **representative icon button** that opens an `AlertDialog`
  or `ModalBottomSheet` containing all actions and relevant detail.

---

## [UI-CONV-002] Progressive Disclosure for Status + Action Pairs

### Requirement
When a list item must show **both** status information (a label, icon,
or text indicating current state) **and** an action that operates on that
state, the status and action MUST be placed inside a dialog or bottom
sheet — not rendered inline in the list row.

The list row MAY show a single icon button whose icon reflects the
current state (e.g. green `phonelink` = kiosk linked). Tapping that
button opens the detail dialog.

### Rationale
Inline status + action pairs consume disproportionate horizontal space
and mix information hierarchy: the row becomes both a data display and a
control surface simultaneously. Progressive disclosure keeps the list
scannable and reserves full-width layout for the detail view.

### Example (correct pattern)
```
List row:  [Room name]  [phonelink icon — green]   (one button, state reflected in icon)
  ↓ tap
Dialog:    "Kiosk Linked"
           Device: abc123…
           Since: Jan 15, 2026
           [Close]  [Revoke ▸]
```

### Not Allowed
```
List row:  [Room name]  [● abc123]  [link_off ▸]   (status text + action both inline)
```

---

## [UI-CONV-003] Destructive Actions Require Confirmation

### Requirement
Any action that permanently deletes, revokes, or rejects data MUST be
confirmed via an `AlertDialog` before executing. The confirmation dialog
MUST:
- Name what will be destroyed in the `content` text.
- Use a red `foregroundColor` on the destructive action button
  (`TextButton.styleFrom(foregroundColor: Colors.red)`).
- Offer a neutral "Cancel" or "Close" button as the first action.

### Rationale
Destructive actions are irreversible and are frequently placed next to
non-destructive ones (edit, view). A confirmation step prevents
accidental data loss.

---

## [UI-CONV-004] Touch Target Minimum

### Requirement
Every interactive element in a list row MUST have a minimum touch target
of **48 × 48 dp**. Use `IconButton` (which enforces this by default)
rather than wrapping a raw `Icon` in a `GestureDetector` or `InkWell`.

---

## [UI-CONV-005] Dialog Presentation — Form vs. Simple

### Requirement

Portal dialogs fall into two categories, each with a distinct layout
strategy that adapts to viewport width. The breakpoint **650 dp** matches
the `isSmallView()` threshold used throughout the portal.

#### Category A — Multi-field forms
Dialogs that present a form with several fields (e.g. booking editor,
amendment proposal form) where the content would require internal
scrolling inside a constrained dialog on a narrow screen.

| Viewport | Presentation |
|---|---|
| Narrow (< 650 dp) | `Dialog.fullscreen` wrapping a `Scaffold`: `AppBar` with title, leading close button (`Icons.close`), primary action in `actions`; scrollable body via `SingleChildScrollView` with 16 dp padding inside `SafeArea`. |
| Wide (≥ 650 dp) | `AlertDialog` with `SizedBox(width: 480)` content, `SingleChildScrollView` inside, Cancel + primary action in `actions`. |

#### Category B — Simple / confirmatory dialogs
Dialogs with a small, fixed amount of content: scope pickers, confirm/
cancel prompts, informational alerts, single-choice selectors. These
MUST use a plain `AlertDialog` at all viewport sizes — fullscreen is
reserved for forms.

### Rationale
On narrow mobile screens a multi-field form crammed into an `AlertDialog`
creates awkward bounded scrolling and wastes vertical space with dialog
chrome. A fullscreen layout gives the form its natural scroll axis and
matches the mental model of a dedicated editor screen. Conversely,
wrapping a two-item scope picker in a fullscreen dialog is disorienting
and over-engineered.

### Canonical implementation
The `_showPannelAsDialog` method in `view_bookings_screen.dart`
(`Dialog.fullscreen` + `RequestEditor`) and `showProposeAmendmentDialog`
in `propose_amendment_dialog.dart` (responsive `_buildFullscreen` /
`_buildDialog`) are the reference implementations for Category A.

---

## Known Violations (to be remediated)

The following existing widgets were identified as violating these
conventions at the time this spec was written. Each SHOULD be addressed
before the next minor release.

| Widget | File | Violation |
|--------|------|-----------|
| `RoomTile` trailing | `ui/widgets/room_list_widget.dart` | [UI-CONV-001]: 3 interactive elements (kiosk status + edit + delete) |
| Admin request row trailing | `ui/widgets/org_settings/admin_widget.dart` | [UI-CONV-001]: 2 buttons (approve + deny) |
| `BookingTile` trailing | `ui/widgets/booking_list/booking_lists.dart` | [UI-CONV-001]: 2–3 buttons depending on booking state (pending=3, conflicts=2, recurring=2) |
