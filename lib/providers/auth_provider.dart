import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_gathering/services/auth_service.dart';
import 'package:the_gathering/services/supabase_service.dart';

/// Auth state for the app.
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final String? info;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.info,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    String? info,
    bool clearError = false,
    bool clearInfo = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      info: clearInfo ? null : (info ?? this.info),
    );
  }

  /// Session present = signed in.
  /// Phone is preferred for trust (see profile/phone_verified) but must not
  /// block the app when Supabase Phone provider is disabled.
  bool get isAuthenticated => user != null;
}

/// Manages authentication state reactively.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final AuthService _authService = AuthService();

  void _init() {
    try {
      SupabaseService.client.auth.onAuthStateChange.listen((data) {
        final u = data.session?.user;
        state = state.copyWith(
          user: u,
          clearUser: u == null,
          isLoading: false,
        );
      });

      final currentUser = SupabaseService.currentUser;
      if (currentUser != null) {
        state = state.copyWith(user: currentUser);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Auth failed to start. Check Supabase configuration. ($e)',
      );
    }
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    String phone = '',
    required bool affirmedAttestation,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
    );
    try {
      final result = await _authService.signUp(
        email: email,
        password: password,
        phone: phone,
        affirmedAttestation: affirmedAttestation,
      );
      final currentUser = SupabaseService.currentUser;
      state = state.copyWith(
        user: currentUser,
        isLoading: false,
        clearError: true,
        info: result.message,
      );
      return result;
    } catch (e) {
      final message = _friendly(e);
      state = state.copyWith(isLoading: false, error: message, clearInfo: true);
      rethrow;
    }
  }

  Future<void> verifyPhone({
    required String phone,
    required String otp,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
    );
    try {
      await _authService.verifyPhone(phone: phone, otp: otp);
      await _authService.ensureProfileExists();
      final currentUser = SupabaseService.currentUser;
      state = state.copyWith(
        user: currentUser,
        isLoading: false,
        clearError: true,
        info: 'Phone verified.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendly(e),
        clearInfo: true,
      );
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
    );
    try {
      await _authService.signInWithEmail(email: email, password: password);
      await _authService.ensureProfileExists();
      final currentUser = SupabaseService.currentUser;
      state = state.copyWith(
        user: currentUser,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendly(e),
        clearInfo: true,
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      await _authService.signOut();
    } finally {
      // Always clear local state even if network sign-out is flaky.
      state = const AuthState();
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true, clearInfo: true);
  }

  void setError(String message) {
    state = state.copyWith(error: message, clearInfo: true, isLoading: false);
  }

  void setInfo(String message) {
    state = state.copyWith(info: message, clearError: true);
  }

  static String _friendly(Object e) {
    var raw = e.toString();
    raw = raw.replaceFirst(RegExp(r'^(Exception|AuthException):\s*'), '');
    raw = raw.trim();
    final lower = raw.toLowerCase();
    if (lower.contains('already registered') ||
        lower.contains('user already exists')) {
      return 'That email already has an account. Use Sign In instead.';
    }
    if (lower.contains('invalid login') || lower.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    return raw.isEmpty ? 'Something went wrong. Please try again.' : raw;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
