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
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Full access requires both a session user and a verified phone number.
  bool get isAuthenticated {
    final currentUser = user;
    return currentUser != null && (currentUser.phone?.isNotEmpty ?? false);
  }
}

/// Manages authentication state reactively.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final AuthService _authService = AuthService();

  void _init() {
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final u = data.session?.user;
      state = state.copyWith(
        user: u,
        clearUser: u == null,
        isLoading: false,
        clearError: true,
      );
    });

    final currentUser = SupabaseService.currentUser;
    if (currentUser != null) {
      state = state.copyWith(user: currentUser);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String phone,
    required bool affirmedAttestation,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.signUp(
        email: email,
        password: password,
        phone: phone,
        affirmedAttestation: affirmedAttestation,
      );
      // User may exist from email signup; full isAuthenticated still needs phone verify.
      final currentUser = SupabaseService.currentUser;
      state = state.copyWith(
        user: currentUser,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> verifyPhone({
    required String phone,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.verifyPhone(phone: phone, otp: otp);
      await _authService.ensureProfileExists();
      final currentUser = SupabaseService.currentUser;
      state = state.copyWith(
        user: currentUser,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
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
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
