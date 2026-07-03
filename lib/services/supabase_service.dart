import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase service wrapper for The Gathering (PR1 foundational)
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize any realtime or other clients here in future PRs.
  static Future<void> initialize() async {
    // Already initialized in main.dart
  }

  /// Example: Sign up with email (basic). Phone handled separately for verification.
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Phone OTP - mandatory per PR1 design
  static Future<void> sendPhoneOtp(String phone) async {
    await client.auth.signInWithOtp(phone: phone);
  }

  static Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    return await client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Self-attestation will be stored in user metadata or profiles table.
  static Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    await client.auth.updateUser(
      UserAttributes(data: metadata),
    );
  }

  static User? get currentUser => client.auth.currentUser;
}
