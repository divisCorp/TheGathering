import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase service wrapper for The Gathering (PR1 foundational)
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize any realtime or other clients here in future PRs.
  static Future<void> initialize() async {
    // Already initialized in main.dart
  }

  /// Sign up with email (basic). Phone handled separately for verification.
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Phone OTP — mandatory per PR1 design.
  /// Use signInWithOtp for unauthenticated phone auth flows.
  static Future<void> sendPhoneOtp(String phone) async {
    await client.auth.signInWithOtp(phone: phone);
  }

  /// Send phone verification for an *authenticated* user (e.g. after email signup).
  /// Links the phone to the current user account.
  static Future<void> sendPhoneVerificationForCurrentUser(String phone) async {
    await client.auth.updateUser(UserAttributes(phone: phone));
  }

  static Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    return client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Self-attestation and flags stored in user metadata / profiles.
  static Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    await client.auth.updateUser(
      UserAttributes(data: metadata),
    );
  }

  static User? get currentUser => client.auth.currentUser;
}
