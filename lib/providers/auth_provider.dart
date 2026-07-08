import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_gathering/services/auth_service.dart';
import 'package:the_gathering/services/supabase_service.dart';

/// Auth state for the app.
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
}

/// Manages authentication state reactively.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final AuthService _authService = AuthService();

  void _init() {
    // Listen to auth state changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      state = state.copyWith(
        user: session?.user,
        isLoading: false,
        error: null,
      );
    });

    // Set initial state
    final currentUser = SupabaseService.currentUser;
    state = state.copyWith(user: currentUser);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String phone,
    required bool affirmedAttestation,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signUp(
        email: email,
        password: password,
        phone: phone,
        affirmedAttestation: affirmedAttestation,
      );
      // Navigation handled in UI after OTP
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> verifyPhone({
    required String phone,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.verifyPhone(phone: phone, otp: otp);
      await _authService.ensureProfileExists();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signInWithEmail(email: email, password: password);
      await _authService.ensureProfileExists();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
