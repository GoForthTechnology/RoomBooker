## Context

After adding the HTML/CSS splash screen, a secondary Flutter-based loading spinner (`CircularProgressIndicator`) flashes briefly. This happens because the initial Flutter frame rendered by `LandingScreen` or `ViewBookingsScreen` is often a loading state while checking `SharedPreferences` for redirects or waiting for a synchronous stream to emit its first value.

## Decisions

We will remove the `CircularProgressIndicator` during the initial redirect on the `LandingScreen` and the initial wait state on `ViewBookingsScreen`. Instead, we will render a blank `Scaffold()` or `SizedBox.shrink()`. Since the splash screen has a white background, transitioning from the splash screen to a blank white screen and then immediately to the actual UI is much less jarring than transitioning to a blue spinner and then to the UI.

## Risks / Trade-offs

- **Trade-off:** If the redirect or loading takes an unusually long time, the user might see a blank white screen for a second or two without a spinner. However, because these checks are largely synchronous or rely on local cache (SharedPreferences), this duration is typically on the order of milliseconds, making the blank screen practically imperceptible.
