import 'package:the_gathering/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth service implementing The Gathering requirements from design doc PR1.
/// - Email + phone
/// - **Mandatory phone verification**
/// - Self-attestation with explicit wording and ban consequences
/// - Verification queue flag for backend (stub for now)
class AuthService {
  static const String _attestationText = 
      'I affirm under penalty of community removal that I am a current, active or believing member of The Church of Jesus Christ of Latter-day Saints in good standing and will abide by all app standards and terms; false claims will result in permanent ban and may be reported.';

  /// Returns the required attestation text for UI display.
  static String get attestationText => _attestationText;

  /// Sign up flow for PR1.
  /// 1. Basic email/password signup
  /// 2. Send phone OTP (mandatory)
  /// 3. User must affirm attestation
  /// 4. On success, set metadata with attestation + is_verified_member = false (pending review)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String phone,
    required bool affirmedAttestation,
  }) async {
    if (!affirmedAttestation) {
      throw Exception('You must affirm the membership attestation to continue.');
    }

    // Step 1: Email signup
    final response = await SupabaseService.signUpWithEmail(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // Step 2: Send phone OTP (mandatory verification)
      await SupabaseService.sendPhoneOtp(phone);

      // Store attestation and verification pending flag in metadata
      await SupabaseService.updateUserMetadata({
        'phone': phone,
        'attestation_affirmed': true,
        'attestation_text': _attestationText,
        'is_verified_member': false, // Pending review queue per design
        'verification_status': 'pending_review', // For PR1 stub
        'created_at': DateTime.now().toIso8601String(),
      });

      // TODO(PR7+): Trigger backend review queue (e.g. via edge function or table insert)
    }

    return response;
  }

  /// Verify the phone OTP. Required before full access.
  Future<AuthResponse> verifyPhone({
    required String phone,
    required String otp,
  }) async {
    final response = await SupabaseService.verifyPhoneOtp(
      phone: phone,
      token: otp,
    );

    if (response.user != null) {
      // Mark phone verified (still pending member review for full features)
      await SupabaseService.updateUserMetadata({
        'phone_verified': true,
        'phone_verified_at': DateTime.now().toIso8601String(),
      });
    }

    return response;
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  bool get isAuthenticated => SupabaseService.currentUser != null;
}
