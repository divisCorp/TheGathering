import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_gathering/services/supabase_service.dart';

/// Outcome of the create-account flow (so the UI can react clearly).
enum SignUpOutcome {
  /// SMS OTP was sent — show OTP entry.
  phoneOtpSent,

  /// Account created but email confirmation is required before sign-in.
  emailConfirmationRequired,

  /// Session is ready (email autoconfirm and/or no phone step needed).
  sessionReady,
}

class SignUpResult {
  final SignUpOutcome outcome;
  final AuthResponse response;
  final String? message;
  final bool phoneProviderUnavailable;

  const SignUpResult({
    required this.outcome,
    required this.response,
    this.message,
    this.phoneProviderUnavailable = false,
  });
}

/// Auth service implementing The Gathering requirements from design doc PR1.
/// - Email + phone (phone preferred; graceful when SMS provider is disabled)
/// - Self-attestation with explicit wording and ban consequences
/// - Verification queue flag for backend (see PR7+ for full implementation)
class AuthService {
  static const String _attestationText =
      'I affirm under penalty of community removal that I am a current, active or believing member of The Church of Jesus Christ of Latter-day Saints in good standing and will abide by all app standards and terms; false claims will result in permanent ban and may be reported.';

  /// Returns the required attestation text for UI display.
  static String get attestationText => _attestationText;

  /// Sign up flow:
  /// 1. Email/password signup
  /// 2. Attempt phone OTP (when provider enabled)
  /// 3. Persist attestation metadata when a session exists
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    String phone = '',
    required bool affirmedAttestation,
  }) async {
    if (!affirmedAttestation) {
      throw Exception(
        'You must affirm the membership attestation to continue.',
      );
    }
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Email and password are required.');
    }

    AuthResponse response;
    try {
      response = await SupabaseService.signUpWithEmail(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(_friendlyAuthMessage(e));
    }

    if (response.user == null) {
      throw Exception('Sign up failed. Please try again.');
    }

    final hasSession = response.session != null;
    var phoneOtpSent = false;
    var phoneProviderUnavailable = false;
    final phoneTrimmed = phone.trim();

    // Optional phone — only attempt SMS when a number is provided.
    if (phoneTrimmed.isNotEmpty) {
      try {
        await SupabaseService.sendPhoneOtp(phoneTrimmed);
        phoneOtpSent = true;
      } on AuthException catch (e) {
        phoneProviderUnavailable = _isPhoneProviderDisabled(e);
        if (!phoneProviderUnavailable) {
          throw Exception(_friendlyAuthMessage(e));
        }
      } catch (e) {
        final msg = e.toString();
        if (_looksLikePhoneProviderDisabled(msg)) {
          phoneProviderUnavailable = true;
        } else {
          rethrow;
        }
      }
    } else {
      // Beta: SMS often disabled; email-only accounts are allowed.
      phoneProviderUnavailable = true;
    }

    if (hasSession) {
      if (phoneTrimmed.isNotEmpty && !phoneProviderUnavailable) {
        try {
          await SupabaseService.sendPhoneVerificationForCurrentUser(phoneTrimmed);
        } catch (_) {
          // Non-fatal: unauth OTP may already cover verification.
        }
      }

      await SupabaseService.updateUserMetadata({
        if (phoneTrimmed.isNotEmpty) 'phone': phoneTrimmed,
        'attestation_affirmed': true,
        'attestation_text': _attestationText,
        'is_verified_member': false,
        'verification_status': 'pending_review',
        'phone_provider_unavailable': phoneProviderUnavailable,
        'created_at': DateTime.now().toIso8601String(),
      });

      await ensureProfileExists();
    }

    if (phoneOtpSent) {
      return SignUpResult(
        outcome: SignUpOutcome.phoneOtpSent,
        response: response,
        message: 'Verification code sent to your phone. Enter the OTP below.',
      );
    }

    if (hasSession) {
      return SignUpResult(
        outcome: SignUpOutcome.sessionReady,
        response: response,
        phoneProviderUnavailable: phoneProviderUnavailable,
        message: 'Account created. Welcome to The Gathering!',
      );
    }

    return SignUpResult(
      outcome: SignUpOutcome.emailConfirmationRequired,
      response: response,
      phoneProviderUnavailable: phoneProviderUnavailable,
      message:
          'Account created. Check your email to confirm, then use Sign In.',
    );
  }

  /// Verify the phone OTP. Required for full trust signals when SMS is enabled.
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
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    // Clear local + server session so the next visitor does not inherit this login.
    await SupabaseService.client.auth.signOut(scope: SignOutScope.global);
  }

  bool get isAuthenticated => SupabaseService.currentUser != null;

  /// Ensure a profile row exists for the current user (called after signup/verify).
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

  static bool _isPhoneProviderDisabled(AuthException e) {
    final code = (e.code ?? '').toLowerCase();
    final msg = e.message.toLowerCase();
    return code.contains('phone_provider') ||
        msg.contains('phone provider') ||
        msg.contains('unsupported phone provider') ||
        msg.contains('phone provider disabled');
  }

  static bool _looksLikePhoneProviderDisabled(String msg) {
    final m = msg.toLowerCase();
    return m.contains('phone_provider') ||
        m.contains('unsupported phone provider') ||
        m.contains('phone provider disabled');
  }

  static String _friendlyAuthMessage(AuthException e) {
    final msg = e.message.trim();
    final lower = msg.toLowerCase();
    if (lower.contains('already registered') ||
        lower.contains('already been registered') ||
        lower.contains('user already exists')) {
      return 'That email already has an account. Use Sign In, or Sign out first if you are on a shared device.';
    }
    if (lower.contains('password')) {
      return msg;
    }
    if (msg.isEmpty) return 'Authentication failed. Please try again.';
    return msg;
  }
}
