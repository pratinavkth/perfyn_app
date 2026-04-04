# Perfyn Progress Snapshot

## What has been done

### App shell
- `lib/main.dart`
  - Loads `.env`
  - Initializes Supabase
  - Starts the app with `ProviderScope`
  - Launches `FinWiseApp`

- `lib/app/app.dart`
  - Switched from plain `MaterialApp` to `MaterialApp.router`
  - Connected app theme
  - Connected app router

### Providers
- `lib/app/providers/app_providers.dart`
  - Added `supabaseClientProvider`

- `lib/features/auth/providers/auth_prov-+ider.dart`
  - Added `currentSessionProvider`
  - Added `authStateChangesProvider`
  - Added `authControllerProvider`
  - Added auth methods:
    - `signIn`
    - `signUp`
    - `signOut`

### Theme
- `lib/core/theme/app_colors.dart`
  - Added shared project color palette

- `lib/core/theme/app_theme.dart`
  - Added light theme
  - Added dark theme
  - Styled input fields and buttons

### Routing
- `lib/core/router/app_router.dart`
  - Added `GoRouter`
  - Added routes for:
    - splash
    - login
    - register
    - temporary home placeholder
  - Added temporary signed-in home screen with sign-out button

### Auth screens
- `lib/features/auth/presentation/splash_screen.dart`
  - Created animated splash screen
  - Added gradient background
  - Added animated logo and text entrance
  - Auto-navigates to login or home based on session

- `lib/features/auth/presentation/login_screen.dart`
  - Created login UI
  - Added form validation
  - Connected Supabase sign-in
  - Added navigation to signup

- `lib/features/auth/presentation/register_screen.dart`
  - Created signup UI
  - Added form validation
  - Connected Supabase sign-up
  - Added navigation back to login

## Dependency adjustment made

`pubspec.yaml` was updated to avoid the Riverpod and Flutter SDK mismatch that caused:

`No named parameter with the name 'scheduleNewFrame'`

Updated versions:
- `riverpod: ^2.6.1`
- `flutter_riverpod: ^2.6.1`
- `riverpod_annotation: ^2.6.1`

## Current state

The auth flow foundation is now present:
- splash screen
- login screen
- signup screen
- theme
- router
- Supabase auth controller

## Still pending

- Run `flutter pub get`
- Run `dart format`
- Run `flutter analyze`
- Run the app on device/emulator
- Replace temporary `/home` placeholder with actual dashboard screen
- Add onboarding screen if needed
- Connect observer/logger if you want Riverpod logging

## Remaining work plan



### Feature modules to build next
- Dashboard feature
  - home screen
  - balance card
  - spending chart
  - recent transactions
- Transactions feature
  - entities and DTOs
  - repository and datasource
  - providers
  - list, add, edit, and delete flows
- Goals feature
  - goals listing
  - goal detail
  - no-spend challenge flow
- Insights feature
  - analytics providers
  - pie/bar chart screens
  - category drill-down
- Settings feature
- Notifications feature

### Architecture work still pending
- Fill empty `data`, `domain`, and `usecases` files
- Add repository implementations for each feature
- Connect `failures.dart` and `exceptions.dart` into the data layer
- Add route guards for authenticated and unauthenticated users
- Add loading, empty, and error states across screens
- Wire shared widgets into feature screens

### Backend integration work still pending
- Connect app screens to Supabase queries and mutations
- Add CRUD operations for transactions and goals
- Add profile-based user data handling
- Add notification fetch and display flow
- Add sync queue processing if offline support is needed
- Add secure user-scoped access patterns for Supabase

## Supabase PostgreSQL tables

We have created or planned the following PostgreSQL tables in Supabase:

- `profiles`
- `transactions`
- `goals`
- `nospend_challenge`
- `notifications`
- `sync_queue`

### Purpose of these tables
- `profiles`
  - stores user profile details
- `transactions`
  - stores income and expense records
- `goals`
  - stores savings goals and progress data
- `nospend_challenge`
  - stores challenge progress and streak-related data
- `notifications`
  - stores app notification entries
- `sync_queue`
  - stores queued sync actions for pending/offline operations

