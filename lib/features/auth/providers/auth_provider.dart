import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/app/providers/app_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final currentSessionProvider = Provider<Session?>((ref) {
  // Re-evaluate whenever auth state changes (login, logout, token refresh).
  ref.watch(authStateChangesProvider);
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentSession;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthController(client);
});

final authRefreshProvider = Provider<AuthRefreshNotifier>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final notifier = AuthRefreshNotifier(client.auth.onAuthStateChange);
  ref.onDispose(notifier.dispose);
  return notifier;
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._client) : super(const AsyncData(null));

  final SupabaseClient _client;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signOut();
    });
  }
}

class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
