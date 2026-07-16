import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_gathering/services/supabase_service.dart';

/// Auth service implementing The Gathering requirements from design doc PR1.
/// - Email + phone
/// - **Mandatory phone verification**
/// - Self-attestation with explicit wording and ban consequences
/// - Verification queue flag for backend (see PR7+ for full implementation)
class AuthService {
  static const String _attestationText =
      'I affirm under penalty of community removal that I am a current, active or believing member of The Church of Jesus Christ of Latter-day Saints in good standing and will abide by all app standards and terms; false claims will result in permanent ban and may be reported.';

  /// Returns the required attestation text for UI display.
  static String get attestationText => _attestationText;

  /// Sign up flow for PR1.
  /// 1. Basic email/password signup
  /// 2. Send phone OTP (mandatory) via unauth OTP so SMS is always delivered
  /// 3. User must affirm attestation
  /// 4. On success (when session exists), set metadata + profile row
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String phone,
    required bool affirmedAttestation,
  }) async {
    if (!affirmedAttestation) {
      throw Exception('You must affirm the membership attestation to continue.');
    }

    final response = await SupabaseService.signUpWithEmail(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Sign up failed. Please try again.');
    }

    // Always send phone OTP so verification works even when email confirm
    // is enabled and there is no session yet after signUp.
    await SupabaseService.sendPhoneOtp(phone);

    final hasSession = response.session != null;
    if (hasSession) {
      // Link phone on the authenticated user when possible.
      try {
        await SupabaseService.sendPhoneVerificationForCurrentUser(phone);
      } catch (_) {
        // Non-fatal: unauth OTP already sent; verifyPhone will complete auth.
      }

      await SupabaseService.updateUserMetadata({
        'phone': phone,
        'attestation_affirmed': true,
        'attestation_text': _attestationText,
        'is_verified_member': false,
        'verification_status': 'pending_review',
        'created_at': DateTime.now().toIso8601String(),
      });

      await ensureProfileExists();
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
      await SupabaseService.updateUserMetadata({
        'phone': phone,
        'phone_verified': true,
        'phone_verified_at': DateTime.now().toIso8601String(),
        'attestation_affirmed': true,
        'attestation_text': _attestationText,
        'is_verified_member': false,
        'verification_status': 'pending_review',
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

  /// Ensure a profile row exists for the current user (called after signup/verify).
  /// Uses upsert so it's safe.
  Future<void> ensureProfileExists() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      final meta = user.userMetadata ?? {};
      await SupabaseService.client.from('profiles').upsert({
        'id': user.id,
        'display_name':
            meta['display_name'] ?? user.email?.split('@').first ?? 'Member',
        'is_verified_member': meta['is_verified_member'] ?? false,
        'phone_verified': meta['phone_verified'] ?? false,
        'verification_status': meta['verification_status'] ?? 'pending_review',
        'created_at': DateTime.parse(
          user.createdAt as String? ?? DateTime.now().toIso8601String(),
        ).toIso8601String(),
      });
    } catch (_) {
      // Non-fatal; profile screen can still save.
    }
  }
}
