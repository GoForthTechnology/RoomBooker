# Proposal: Calendar Swipe Optimization

## Problem
Users experience UI jank and "pop-in" behavior when swiping between days in the Syncfusion calendar's day view. This is primarily caused by:
1. **Late Data Loading**: The `displayDate` property on the `CalendarController` only updates after the swipe animation completes, delaying the trigger for fetching new data.
2. **Heavy Rebuilds**: The entire `SfCalendar` widget is rebuilt via a `StreamBuilder` whenever new data is emitted, leading to dropped frames during or immediately after transitions.
3. **Lack of Pre-fetching**: There is no proactive fetching of data for adjacent days while a swipe is in progress.

## Proposed Solution
1. **Earlier Date Detection**: Implement the `onViewChanged` callback on `SfCalendar`. This callback provides the visible dates earlier than the `controller.displayDate` property, allowing for proactive window updates.
2. **Pre-fetching Logic**: Update `CalendarViewModel` to maintain a slightly larger "hot" window of data and trigger background fetches as soon as a swipe begins towards a new day.
3. **Optimized Build Strategy**: 
    - Decouple the `SfCalendar` configuration from the data stream where possible.
    - Ensure the `CalendarDataSource` updates its internal appointments list and notifies listeners rather than forcing a full widget rebuild of the `SfCalendar`.
4. **Loading State Refinement**: Ensure that if data is already present in the "padded window", the UI transition remains seamless without showing a loading state or "shrunk" sized boxes.

## Goals
- Eliminate the visible "empty day" state during swipe transitions.
- Maintain 60fps during day-view transitions.
- Reduce the number of full `SfCalendar` widget reconstructions.
