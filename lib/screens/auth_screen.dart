import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_gathering/providers/auth_provider.dart';
import 'package:the_gathering/providers/current_profile_provider.dart';
import 'package:the_gathering/services/auth_service.dart';

/// Auth Screen for The Gathering (PR1)
/// Implements:
/// - Email + Phone
/// - Phone OTP when Supabase Phone provider is enabled
/// - Self-attestation with exact wording and consequences
/// - Basic login path
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _affirmedAttestation = false;
  bool _phoneOtpSent = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Normalize phone to E.164-ish form: strip separators, ensure leading +.
  String _normalizePhone(String input) {
    var p = input.trim().replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (p.isNotEmpty && !p.startsWith('+')) {
      p = '+$p';
    }
    return p;
  }

  void _notify(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : null,
        duration: Duration(seconds: isError ? 6 : 4),
      ),
    );
  }

  Future<void> _handleSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phoneRaw = _phoneController.text.trim();
    final phone = _normalizePhone(phoneRaw);
    final authNotifier = ref.read(authProvider.notifier);

    authNotifier.clearError();

    if (email.isEmpty || password.isEmpty || phoneRaw.isEmpty) {
      authNotifier.setError(
        'Please enter email, password, and phone number.',
      );
      _notify('Please enter email, password, and phone number.', isError: true);
      return;
    }
    if (password.length < 6) {
      authNotifier.setError('Password must be at least 6 characters.');
      _notify('Password must be at least 6 characters.', isError: true);
      return;
    }
    if (!_affirmedAttestation) {
      authNotifier.setError(
        'Check the membership attestation box to create an account.',
      );
      _notify(
        'Check the membership attestation box to create an account.',
        isError: true,
      );
      return;
    }

    try {
      final result = await authNotifier.signUp(
        email: email,
        password: password,
        phone: phone,
        affirmedAttestation: _affirmedAttestation,
      );

      if (!mounted) return;

      switch (result.outcome) {
        case SignUpOutcome.phoneOtpSent:
          setState(() => _phoneOtpSent = true);
          _notify(result.message ?? 'Verification code sent.');
          break;
        case SignUpOutcome.sessionReady:
          _notify(result.message ?? 'Account created.');
          await ref.read(currentProfileProvider.notifier).refresh();
          if (!mounted) return;
          context.go('/profile');
          break;
        case SignUpOutcome.emailConfirmationRequired:
          _notify(result.message ?? 'Check your email to confirm.', isError: false);
          // Switch to Sign In so the next step is obvious.
          setState(() {
            _isLogin = true;
            _phoneOtpSent = false;
          });
          break;
      }
    } catch (e) {
      if (!mounted) return;
      // Error already on authState; reinforce with snackbar.
      final msg = ref.read(authProvider).error ?? e.toString();
      _notify(msg, isError: true);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _normalizePhone(_phoneController.text);
    final otp = _otpController.text.trim();
    final authNotifier = ref.read(authProvider.notifier);

    if (otp.isEmpty) {
      authNotifier.setError('Please enter the SMS verification code.');
      _notify('Please enter the SMS verification code.', isError: true);
      return;
    }

    authNotifier.clearError();

    try {
      await authNotifier.verifyPhone(phone: phone, otp: otp);
      if (!mounted) return;
      await ref.read(currentProfileProvider.notifier).refresh();
      if (!mounted) return;
      context.go('/profile');
    } catch (e) {
      if (!mounted) return;
      final msg = ref.read(authProvider).error ?? e.toString();
      _notify(msg, isError: true);
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final authNotifier = ref.read(authProvider.notifier);

    authNotifier.clearError();

    if (email.isEmpty || password.isEmpty) {
      authNotifier.setError('Please enter email and password.');
      _notify('Please enter email and password.', isError: true);
      return;
    }

    try {
      await authNotifier.signIn(email: email, password: password);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      final msg = ref.read(authProvider).error ?? e.toString();
      _notify(msg, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Gathering'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Welcome to The Gathering',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Uplifting activities. Genuine friendships. Right where you are.',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Sign In')),
                ButtonSegment(value: false, label: Text('Create Account')),
              ],
              selected: {_isLogin},
              onSelectionChanged: isLoading
                  ? null
                  : (set) {
                      setState(() {
                        _isLogin = set.first;
                        _phoneOtpSent = false;
                        _otpController.clear();
                      });
                      ref.read(authProvider.notifier).clearError();
                    },
            ),
            const SizedBox(height: 20),

            // Always-visible status (more reliable than snackbars alone on web)
            if (authState.error != null) ...[
              _StatusBanner(
                message: authState.error!,
                isError: true,
              ),
              const SizedBox(height: 12),
            ] else if (authState.info != null) ...[
              _StatusBanner(
                message: authState.info!,
                isError: false,
              ),
              const SizedBox(height: 12),
            ],

            if (!_isLogin) ...[
              if (!_phoneOtpSent) ...[
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    helperText: 'At least 6 characters',
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+1 555 123 4567',
                    border: OutlineInputBorder(),
                    helperText: 'Include country code (e.g. +1 for US)',
                  ),
                  keyboardType: TextInputType.phone,
                  enabled: !isLoading,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Membership Attestation (Required)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AuthService.attestationText,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: _affirmedAttestation,
                        onChanged: isLoading
                            ? null
                            : (val) {
                                setState(() => _affirmedAttestation = val ?? false);
                                if (val == true) {
                                  ref.read(authProvider.notifier).clearError();
                                }
                              },
                        title: const Text('I affirm the above statement'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Always wired — never silent-disabled when attestation unchecked.
                FilledButton(
                  onPressed: isLoading ? null : _handleSignup,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Create Account & Send Verification Code',
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
                if (!_affirmedAttestation) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tip: check the attestation box above, then tap Create Account.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ] else ...[
                Text(
                  'We sent a code to ${_normalizePhone(_phoneController.text)}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'Enter SMS Verification Code',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isLoading,
                  onSubmitted: (_) {
                    if (!isLoading) _verifyOtp();
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: isLoading ? null : _verifyOtp,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify Phone & Continue'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() {
                            _phoneOtpSent = false;
                            _otpController.clear();
                          });
                          ref.read(authProvider.notifier).clearError();
                        },
                  child: const Text('Back to account details'),
                ),
              ],
            ] else ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                enabled: !isLoading,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) {
                  if (!isLoading) _handleLogin();
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isLoading ? null : _handleLogin,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
              ),
            ],

            const SizedBox(height: 32),
            Text(
              'The Gathering is an independent community tool and is not affiliated with, endorsed by, or sponsored by The Church of Jesus Christ of Latter-day Saints.',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _StatusBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isError
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.primaryContainer;
    final fg = isError
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onPrimaryContainer;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: fg,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
