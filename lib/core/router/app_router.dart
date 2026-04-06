import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:perfyn_app/app/presentation/main_shell_screen.dart';
import 'package:perfyn_app/features/transactions/domain/entities/transaction_record.dart';
import 'package:perfyn_app/features/goals/domain/entities/goal_record.dart';
import 'package:perfyn_app/features/auth/presentation/login_screen.dart';
import 'package:perfyn_app/features/auth/presentation/register_screen.dart';
import 'package:perfyn_app/features/auth/presentation/splash_screen.dart';
import 'package:perfyn_app/features/auth/providers/auth_provider.dart';
import 'package:perfyn_app/features/dashboard/presentation/home_screen.dart';
import 'package:perfyn_app/features/goals/presentation/goals_screen.dart';
import 'package:perfyn_app/features/goals/presentation/goal_detail_screen.dart';
import 'package:perfyn_app/features/insights/presentation/insights_screen.dart';
import 'package:perfyn_app/features/transactions/presentation/transactions_screen.dart';
import 'package:perfyn_app/features/transactions/presentation/add_edit_transaction_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = ref.watch(authRefreshProvider);

  return GoRouter(
    initialLocation: SplashScreen.routePath,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final isLoggedIn = ref.read(currentSessionProvider) != null;
      final location = state.matchedLocation;
      final isAuthPage = location == LoginScreen.routePath ||
          location == RegisterScreen.routePath;
      final isSplash = location == SplashScreen.routePath;

      if (isSplash) {
        return null;
      }

      final isProtectedRoute = location == HomeScreen.routePath ||
          location == TransactionsScreen.routePath ||
          location == GoalsScreen.routePath ||
          location == GoalDetailScreen.routePath ||
          location == InsightsScreen.routePath ||
          location == AddEditTransactionScreen.routePath;

      if (!isLoggedIn && isProtectedRoute) {
        return LoginScreen.routePath;
      }

      if (isLoggedIn && isAuthPage) {
        return HomeScreen.routePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        name: SplashScreen.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        name: LoginScreen.routeName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RegisterScreen.routePath,
        name: RegisterScreen.routeName,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AddEditTransactionScreen.routePath,
        name: 'add-edit-transaction',
        builder: (context, state) => AddEditTransactionScreen(
          transaction: state.extra as TransactionRecord?,
        ),
      ),
      GoRoute(
        path: GoalDetailScreen.routePath,
        name: 'goal-detail',
        builder: (context, state) => GoalDetailScreen(
          goal: state.extra as GoalRecord,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: HomeScreen.routePath,
                name: HomeScreen.routeName,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TransactionsScreen.routePath,
                name: 'transactions',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: GoalsScreen.routePath,
                name: 'goals',
                builder: (context, state) => const GoalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: InsightsScreen.routePath,
                name: 'insights',
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
