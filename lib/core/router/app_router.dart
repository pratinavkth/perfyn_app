import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:perfyn_app/features/auth/presentation/login_screen.dart';
import 'package:perfyn_app/features/auth/presentation/register_screen.dart';
import 'package:perfyn_app/features/auth/presentation/splash_screen.dart';
import 'package:perfyn_app/features/auth/providers/auth_provider.dart';
import 'package:perfyn_app/features/dashboard/presentation/home_screen.dart';

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

      if (!isLoggedIn && location == HomeScreen.routePath) {
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
        path: HomeScreen.routePath,
        name: HomeScreen.routeName,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});
