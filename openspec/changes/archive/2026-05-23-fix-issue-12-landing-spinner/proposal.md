## Why

The user noticed a second spinner that appears briefly after the initial web loading splash screen completes. This occurs on the `LandingScreen` when it decides whether to redirect the user to their last opened organization. We need to eliminate or smooth out this secondary loading state to ensure a seamless startup experience.

## What Changes

- Update `LandingViewModel` to delay setting `_isRedirecting` to `true` unless the redirect is actually happening.
- Currently, `_isRedirecting` starts as `false`, and `init()` is called, which synchronously triggers `_handleInitialNavigation`.
- If a redirect happens, the screen flips to `CircularProgressIndicator` before the navigation takes over.
- We should rethink how the initial redirect works so that it doesn't flash the UI, or we should use the Splash Screen logic to cover this transition.
- The best approach: Since the `LandingViewModel` reads synchronously from `prefsRepo.lastOpenedOrgId` (which is already loaded in `main.dart` via `SharedPreferences.getInstance()`), the redirect happens almost instantly, but the UI flashes.
- We will modify `LandingScreen` so that if `viewModel.shouldShowRedirecting` is true, we display an empty container `SizedBox.shrink()` or keep the branding instead of a `CircularProgressIndicator()`. Alternatively, since the Flutter splash screen might fade out exactly when `LandingScreen` renders its first frame (which happens to be the CircularProgressIndicator), we just replace the `CircularProgressIndicator` with a blank `Scaffold()` or matching background.

## Capabilities

### Modified Capabilities
- `pwa-startup`: Update to include the requirement that there should be no secondary flashing or loading spinners immediately following the initial boot sequence.

## Impact

- `lib/ui/screens/landing/landing.dart`: Remove the `CircularProgressIndicator` during redirect.
