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

  Future<Session?> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      state = const AsyncData(null);
      return response.session ?? _client.auth.currentSession;
    } catch (error, stackTrace) {
      state = AsyncError(AuthFailure.from(error), stackTrace);
      return null;
    }
  }

  Future<Session?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name.trim(),
          'full_name': name.trim(),
        },
      );
      state = const AsyncData(null);
      return response.session ?? _client.auth.currentSession;
    } catch (error, stackTrace) {
      state = AsyncError(AuthFailure.from(error), stackTrace);
      return null;
    }
  }

  Future<void> resetPassword({
    required String email,
  }) async {
    state = const AsyncLoading();
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'prfyn://auth-callback/reset-password',
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(AuthFailure.from(error), stackTrace);
    }
  }

  Future<void> updatePassword({
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await _client.auth.updateUser(
        UserAttributes(password: password),
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(AuthFailure.from(error), stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _client.auth.signOut();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(AuthFailure.from(error), stackTrace);
    }
  }
}

String authErrorMessage(Object error) {
  if (error is AuthFailure) return error.message;
  return 'Something went wrong. Please try again.';
}

class AuthFailure implements Exception {
  AuthFailure(this.message);

  final String message;

  factory AuthFailure.from(Object error) {
    final rawMessage = error is AuthException
        ? error.message
        : error.toString().replaceFirst('Exception: ', '');
    final message = rawMessage.toLowerCase();

    if (message.contains('user already registered') ||
        message.contains('already been registered')) {
      return AuthFailure('An account with this email already exists.');
    }
    if (message.contains('invalid login credentials')) {
      return AuthFailure(
        'No account was found with this email, or the password is incorrect.',
      );
    }
    if (message.contains('email not confirmed')) {
      return AuthFailure('Please confirm your email before signing in.');
    }
    if (message.contains('signup is disabled')) {
      return AuthFailure('New sign-ups are not available right now.');
    }
    if (message.contains('password should be at least')) {
      return AuthFailure('Password must be at least 6 characters long.');
    }
    if (message.contains('same password')) {
      return AuthFailure('Choose a password that is different from the old one.');
    }
    if (message.contains('unable to validate email address') ||
        message.contains('invalid email')) {
      return AuthFailure('Enter a valid email address.');
    }
    if (message.contains('for security purposes')) {
      return AuthFailure(
        'Please wait a moment before requesting another password reset email.',
      );
    }
    if (message.contains('expired') && message.contains('token')) {
      return AuthFailure('This reset link has expired. Please request a new one.');
    }
    if (message.contains('failed host lookup') ||
        message.contains('socketexception') ||
        message.contains('network') ||
        message.contains('connection')) {
      return AuthFailure(
        'Network error. Please check your internet connection and try again.',
      );
    }
    if (message.contains('timeout')) {
      return AuthFailure('The request timed out. Please try again.');
    }
    if (message.contains('429') || message.contains('too many requests')) {
      return AuthFailure('Too many attempts. Please wait a moment and try again.');
    }
    if (message.contains('500') ||
        message.contains('502') ||
        message.contains('503') ||
        message.contains('504')) {
      return AuthFailure(
        'Server error. Please try again in a moment.',
      );
    }
    if (message.contains('unexpected_failure')) {
      return AuthFailure('Unexpected server error. Please try again.');
    }
    if (rawMessage.trim().isNotEmpty) {
      return AuthFailure(_cleanAuthMessage(rawMessage));
    }

    return AuthFailure('Login failed. Please try again.');
  }

  @override
  String toString() => message;
}

String _cleanAuthMessage(String message) {
  var cleaned = message.trim();
  cleaned = cleaned.replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
  cleaned = cleaned.replaceAll('_', ' ');
  if (cleaned.isEmpty) {
    return 'Login failed. Please try again.';
  }
  return cleaned[0].toUpperCase() + cleaned.substring(1);
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
