## 1. Eliminate Secondary Loading States

- [x] 1.1 In `lib/ui/screens/landing/landing.dart`, replace `const Scaffold(body: Center(child: CircularProgressIndicator()))` with `const Scaffold()` when `viewModel.shouldShowRedirecting` is true.
- [x] 1.2 In `lib/ui/screens/view_bookings/view_bookings_screen.dart`, replace `const Center(child: CircularProgressIndicator())` with `const Scaffold()` when `snapshot.connectionState == ConnectionState.waiting` for the initial view state loading.

## 2. Validation

- [x] 2.1 Verify that the application transitions smoothly from the HTML splash screen to the main UI without a flashing spinner.
