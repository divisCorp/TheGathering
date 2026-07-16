import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_gathering/providers/auth_provider.dart';
import 'package:the_gathering/providers/current_profile_provider.dart';
import 'package:the_gathering/services/auth_service.dart';

/// Auth Screen for The Gathering (PR1)
/// Implements:
/// - Email + Phone
/// - **Mandatory phone verification** (OTP)
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

  Future<void> _handleSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phoneRaw = _phoneController.text.trim();
    final phone = _normalizePhone(phoneRaw);

    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.clearError();

    if (email.isEmpty || password.isEmpty || phoneRaw.isEmpty) {
      _showMessage('Please enter email, password, and phone number.');
      return;
    }
    if (!_affirmedAttestation) {
      _showMessage('You must affirm the membership attestation to create an account.');
      return;
    }

    try {
      await authNotifier.signUp(
        email: email,
        password: password,
        phone: phone,
        affirmedAttestation: _affirmedAttestation,
      );

      if (!mounted) return;
      setState(() => _phoneOtpSent = true);
      _showMessage('Verification code sent to your phone. Enter OTP below.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyError(e));
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _normalizePhone(_phoneController.text);
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showMessage('Please enter the SMS verification code.');
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.clearError();

    try {
      await authNotifier.verifyPhone(phone: phone, otp: otp);

      if (!mounted) return;
      await ref.read(currentProfileProvider.notifier).refresh();
      if (!mounted) return;
      // New users complete profile (avatar + interests) after phone verify.
      context.go('/profile');
    } catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyError(e));
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.clearError();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password.');
      return;
    }

    try {
      await authNotifier.signIn(email: email, password: password);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyError(e));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyError(Object e) {
    final raw = e.toString();
    // Strip common Exception: / AuthException: prefixes for cleaner UI.
    return raw
        .replaceFirst(RegExp(r'^(Exception|AuthException):\s*'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final canCreate = _affirmedAttestation && !isLoading;

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
            const SizedBox(height: 40),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Sign In')),
                ButtonSegment(value: false, label: Text('Create Account')),
              ],
              selected: {_isLogin},
              onSelectionChanged: (set) {
                setState(() {
                  _isLogin = set.first;
                  _phoneOtpSent = false;
                  _otpController.clear();
                });
                ref.read(authProvider.notifier).clearError();
              },
            ),
            const SizedBox(height: 24),

            if (authState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
                  border: Border.all(color: Theme.of(context).colorScheme.error),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  authState.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (for verification)',
                    hintText: '+1 555 123 4567',
                    border: OutlineInputBorder(),
                    helperText: 'Include country code (e.g. +1 for US)',
                  ),
                  keyboardType: TextInputType.phone,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),

                // Mandatory self-attestation (exact per design)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Membership Attestation (Required)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                            : (val) => setState(() => _affirmedAttestation = val ?? false),
                        title: const Text('I affirm the above statement'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: canCreate ? _handleSignup : null,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Account & Send Verification Code'),
                ),
                if (!_affirmedAttestation) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Check the attestation box above to enable Create Account.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.error,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ] else ...[
                Text(
                  'We sent a code to ${_normalizePhone(_phoneController.text)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                ElevatedButton(
                  onPressed: isLoading ? null : _verifyOtp,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify Phone & Continue'),
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
                onSubmitted: (_) {
                  if (!isLoading) _handleLogin();
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign In'),
              ),
            ],

            const SizedBox(height: 32),
            Text(
              'The Gathering is an independent community tool and is not affiliated with, endorsed by, or sponsored by The Church of Jesus Christ of Latter-day Saints.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
