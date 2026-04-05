# Perfyn Progress Snapshot

## What has been done

### Offline-First Architecture (Drift + Supabase)
- **Embedded Database:** Added `drift` (SQLite) as the primary edge database for lightning-fast performance without network latency.
- **DAOs:** Created `TransactionsDao` and `GoalsDao` mapping to local tables (`transactions`, `goals`) and `SyncQueueDao` mapping to a background queue.
- **Sync Manager:** Added `SyncManager` which runs a `flushQueue()` process natively in the background upon internet connectivity restoration (monitored by `app.dart`). It resolves Supabase IDs and updates local SQL rows autonomously.
- **Riverpod Streaming:** Replaced network-heavy `FutureProvider` fetchers with `StreamProvider` listeners observing SQLite `watchAll` queries. Offline mutations are instantaneously reflected without spinners. 
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

- `lib/features/auth/providers/auth_provider.dart`
  - Added `currentSessionProvider`
  - Added `authStateChangesProvider`
  - Added `authControllerProvider`
  - Added router refresh listener for auth state changes
  - Added auth methods:
    - `signIn`
    - `signUp`
    - `signOut`
  - Uses Supabase persisted session for login retention

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
    - dashboard home
    - transactions (via StatefulShellRoute)
    - goals (via StatefulShellRoute)
    - insights (via StatefulShellRoute)
  - Added auth-aware redirects for signed-in and signed-out users
  - Redirects authenticated users directly to home
  - Redirects unauthenticated users away from protected routes
  - Fixed unused import warning

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
  - Added session check before redirecting to home

- `lib/features/auth/presentation/register_screen.dart`
  - Created signup UI
  - Added form validation
  - Connected Supabase sign-up
  - Added navigation back to login

### Dashboard (Tab 1 — Home)
- `lib/features/dashboard/presentation/home_screen.dart`
  - Dashboard home screen with greeting header
  - Profile icon opens end drawer
  - Pull-to-refresh to reload data from Supabase
  - Loading, error states handled

- `lib/features/dashboard/providers/dashboard_provider.dart`
  - `dashboardOverviewProvider` — computes overview from real transaction data
  - Calculates total balance, monthly income/expense, savings rate
  - Builds weekly spending data for chart
  - Extracts recent transactions for display

- `lib/features/dashboard/presentation/widgets/balance_card.dart`
  - Total balance card with gradient background
  - Income and expense summary pills
  - Savings rate progress bar

- `lib/features/dashboard/presentation/widgets/spending_chart.dart`
  - Weekly spending bar chart (last 7 days)
  - Gradient bars with highest-day highlight

- `lib/features/dashboard/presentation/widgets/recent_transactions.dart`
  - Recent transactions list (last 5)
  - Income/expense accent colors and icons

### Transactions (Tab 2)
- `lib/features/transactions/domain/entities/transaction_record.dart`
  - `TransactionRecord` entity with `fromJson` factory
  - Maps to Supabase `transactions` table columns
  - `TransactionType` enum (income, expense)

- `lib/features/transactions/data/transaction_repository.dart`
  - `addTransaction()` — inserts to Supabase `transactions` table
  - `fetchTransactions()` — reads user's transactions ordered by date
  - Date formatting helper

- `lib/features/transactions/providers/transaction_provider.dart`
  - `transactionRepositoryProvider` — provides `TransactionRepository`
  - `transactionsProvider` — `FutureProvider.autoDispose` for fetching transactions
  - `quickAddControllerProvider` — `StateNotifierProvider` for add flow
  - Invalidates dashboard on new transaction

- `lib/features/transactions/presentation/transactions_screen.dart`
  - Full transaction list with real Supabase data
  - Search bar and filter chips (All, Income, Expense)
  - Swipe-to-delete functionality (deletes locally immediately, pushes remote delete in background)
  - Quick add action card
  - Loading, error, empty states
  - Pull-to-refresh

- `lib/features/transactions/presentation/quick_add_sheet.dart`
  - Bottom sheet for fast transaction entry
  - Amount input with Rs prefix
  - Expense/Income type toggle pills
  - Category selection chips
  - Date picker and optional notes
  - Saves to Supabase on submit

### Goals (Tab 3)
- `lib/features/goals/domain/entities/goal_record.dart`
  - `GoalRecord` entity with `fromJson` factory
  - Maps to Supabase `goals` table columns
  - `GoalType` enum (savings, noSpend, budget)
  - Helper getters: `progress`, `isCompleted`, `daysRemaining`

- `lib/features/goals/data/goal_repository.dart`
  - `fetchGoals()` — reads user's goals from Supabase
  - `addGoal()` — inserts new goal
  - `updateGoalProgress()` — updates `current_amount`
  - `deleteGoal()` — removes goal by ID

- `lib/features/goals/providers/goal_provider.dart`
  - `goalRepositoryProvider` — provides `GoalRepository`
  - `goalsProvider` — `FutureProvider.autoDispose` for fetching goals
  - `goalControllerProvider` — `StateNotifierProvider` for add/update/delete

- `lib/features/goals/presentation/goals_screen.dart`
  - Goal progress cards with visual progress bars
  - Percentage complete and days remaining display
  - Delete goal via popup menu
  - "Create goal" action card
  - Loading, error, empty states
  - Pull-to-refresh

- `lib/features/goals/presentation/add_goal_sheet.dart`
  - Bottom sheet to create new goals
  - Goal type selector (Savings / Budget / No-spend)
  - Title and target amount inputs
  - Optional deadline date picker
  - Saves to Supabase on submit

- `lib/features/goals/presentation/goal_detail_screen.dart`
  - Dedicated screen with gorgeous animated circular progress rings. 
  - Integrated Milestone tracking chips (25%, 50%, 75%, 100%).
  - Provides progress updation logic baked into the state manager.

### Insights (Tab 4)
- `lib/features/insights/providers/insights_provider.dart`
  - `insightsProvider` — computes analytics from transaction data
  - Category-wise spending breakdown with percentages
  - Weekly comparison (this week vs last week)
  - Top spending category identification
  - Monthly income, expense, and transaction count
  - `weeklyChange` getter for trend calculation

- `lib/features/insights/presentation/insights_screen.dart`
  - Monthly overview card (income, expense, count) with gradient
  - Weekly comparison bars with trend indicator (up/down/flat)
  - Top spending category callout card
  - Full category breakdown with percentage progress bars
  - Loading, error, empty states
  - Pull-to-refresh

### Navigation shell
- `lib/app/presentation/main_shell_screen.dart`
  - `StatefulShellRoute.indexedStack` for 4 tabs
  - Bottom navigation bar: Home, Txn, Goals, Insights
  - Floating action button for quick add
  - End drawer with profile, notifications, about, logout
  - Auth-aware logout flow

### Shared widgets
- `lib/shared/widgets/category_chip.dart`
  - Reusable category selection chip with icon and color
- `lib/shared/widgets/feature_placeholder_screen.dart`
  - Generic placeholder for features not yet built
- `lib/shared/constants/categories.dart`
  - Predefined expense categories (Food, Travel, Shopping, Bills, Health, Entertainment)
  - Predefined income categories (Salary, Freelance, Gift, Refund, Investment, Other)

## Dependency adjustments

`pubspec.yaml` was updated:
- Riverpod versions pinned to avoid Flutter SDK mismatch:
  - `riverpod: ^2.6.1`
  - `flutter_riverpod: ^2.6.1`
  - `riverpod_annotation: ^2.6.1`
- `build_runner` moved from `dependencies` to `dev_dependencies`
- Removed redundant `dotenv` package (already using `flutter_dotenv`)

## Current state

All four navbar tab screens are functional and connected to Supabase:

| Tab | Screen | Supabase Table | Status |
|-----|--------|----------------|--------|
| Tab 1 — Home | `HomeScreen` | `transactions` (derived) | ✅ Read & Computed Locally |
| Tab 2 — Txn | `TransactionsScreen` | `transactions` | ✅ Full CRUD (Add, Edit, Swipe-Delete) |
| Tab 3 — Goals | `GoalsScreen` | `goals` | ✅ Detailed rings, Edit Progress UI |
| Tab 4 — Insights | `InsightsScreen` | `transactions` (derived) | ✅ Live Local Rendering using `fl_chart` |

Additional working flows:
- Auth flow (splash → login/register → home)
- Session persistence (stays logged in)
- Quick add transaction (from any tab via FAB)
- Create goals (savings, budget, no-spend types)
- Delete goals
- Pull-to-refresh on all data screens
- Loading, error, and empty states on all screens
- `flutter analyze` passes with 0 issues

## Still pending

### Feature modules to build next
- Settings feature
  - profile/settings screen (S-13)
  - dark mode toggle
  - currency preference
- Notifications feature
  - notifications screen (S-14)
  - budget alerts, goal milestones

### Architecture work still pending
- Fill empty `data`, `domain`, and `usecases` scaffold files
- Add repository implementations for auth layer
- Connect `failures.dart` and `exceptions.dart` into the data layer
- Add onboarding screen (S-02)
- Connect observer/logger for Riverpod debugging
- Wire shared widgets (amount_display, empty_state, error_state, loading_shimmer)

### Backend integration work still pending
- Add profile-based user data handling (profiles table)
- Add notification fetch and display flow (notifications table)
- Add no-spend challenge tracking (nospend_challenge table)

## Supabase PostgreSQL tables

We have created or planned the following PostgreSQL tables in Supabase:

| Table | Connected in App | Purpose |
|-------|-----------------|---------|
| `transactions` | ✅ Yes | Stores income and expense records |
| `goals` | ✅ Yes | Stores savings goals and progress data |
| `profiles` | ❌ Not yet | Stores user profile details |
| `nospend_challenge` | ❌ Not yet | Stores challenge progress and streak data |
| `notifications` | ❌ Not yet | Stores app notification entries |
| `sync_queue` | ❌ Not yet | Stores queued sync actions for offline ops |

## Notes

- Supabase session persistence is being used, so users remain logged in until the session is invalid or they explicitly log out.
- You can turn off your device's WiFi and fully mutate Goals and Transactions without any app crashes. Data resolves directly on reconnections via `SyncManager` auto-dispatch!
- Dashboard data is computed from real Supabase transaction data (not mocked).
- Insights are derived from the same transactions provider — no separate Supabase queries needed.
- All empty scaffold files (`data/`, `domain/`, `usecases/`) are preserved for future feature development.
