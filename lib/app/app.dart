import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/core/network/connectivity_service.dart';
import 'package:perfyn_app/core/network/sync_manager.dart';
import 'package:perfyn_app/core/router/app_router.dart';
import 'package:perfyn_app/core/theme/app_theme.dart';
import 'package:perfyn_app/features/auth/presentation/reset_password_screen.dart';
import 'package:perfyn_app/features/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinWiseApp extends ConsumerWidget {
  const FinWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    ref.listen(connectivityProvider, (previous, next) {
      final isOnline = next.valueOrNull ?? false;
      final wasOffline = !(previous?.valueOrNull ?? true);

      if (isOnline && wasOffline) {
        ref.read(syncManagerProvider).flushQueue();
      }
    });

    ref.listen(authStateChangesProvider, (previous, next) {
      final authState = next.valueOrNull;
      if (authState?.event == AuthChangeEvent.passwordRecovery) {
        router.go(ResetPasswordScreen.routePath);
      }
    });

    return MaterialApp.router(
      title: 'Perfyn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
