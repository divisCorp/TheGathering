import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_gathering/main.dart' show scaffoldMessengerKey;
import 'package:the_gathering/providers/auth_provider.dart';
import 'package:the_gathering/providers/current_profile_provider.dart';
import 'package:the_gathering/services/auth_service.dart';

/// Auth screen: Sign In + Create Account.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  /// false = Create Account (default after sign-out so new users land here).
  bool _isLogin = false;
  bool _affirmedAttestation = false;
  bool _phoneOtpSent = false;
  /// Local submitting flag — survives independently of provider rebuilds.
  bool _submitting = false;

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

  String _normalizePhone(String input) {
    var p = input.trim().replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (p.isNotEmpty && !p.startsWith('+')) {
      p = '+$p';
    }
    return p;
  }

  void _notify(String message, {bool isError = false}) {
    final messenger =
        scaffoldMessengerKey.currentState ?? ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : null,
        duration: Duration(seconds: isError ? 7 : 4),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (_submitting) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phoneRaw = _phoneController.text.trim();
    final phone = phoneRaw.isEmpty ? '' : _normalizePhone(phoneRaw);
    final authNotifier = ref.read(authProvider.notifier);

    authNotifier.clearError();

    if (email.isEmpty || password.isEmpty) {
      authNotifier.setError('Please enter email and password.');
      _notify('Please enter email and password.', isError: true);
      return;
    }
    if (password.length < 6) {
      authNotifier.setError('Password must be at least 6 characters.');
      _notify('Password must be at least 6 characters.', isError: true);
      return;
    }
    if (!_affirmedAttestation) {
      const msg =
          'Check the membership attestation box, then tap Create Account again.';
      authNotifier.setError(msg);
      _notify(msg, isError: true);
      return;
    }

    setState(() => _submitting = true);
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
          // Router also redirects authenticated users off /auth → /home.
          context.go('/profile');
          break;
        case SignUpOutcome.emailConfirmationRequired:
          _notify(
            result.message ?? 'Check your email to confirm, then Sign In.',
          );
          setState(() {
            _isLogin = true;
            _phoneOtpSent = false;
          });
          break;
      }
    } catch (e) {
      if (!mounted) return;
      final msg = ref.read(authProvider).error ?? e.toString();
      _notify(msg, isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_submitting) return;
    final phone = _normalizePhone(_phoneController.text);
    final otp = _otpController.text.trim();
    final authNotifier = ref.read(authProvider.notifier);

    if (otp.isEmpty) {
      authNotifier.setError('Please enter the SMS verification code.');
      _notify('Please enter the SMS verification code.', isError: true);
      return;
    }

    authNotifier.clearError();
    setState(() => _submitting = true);
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
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleLogin() async {
    if (_submitting) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final authNotifier = ref.read(authProvider.notifier);

    authNotifier.clearError();

    if (email.isEmpty || password.isEmpty) {
      authNotifier.setError('Please enter email and password.');
      _notify('Please enter email and password.', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      await authNotifier.signIn(email: email, password: password);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      final msg = ref.read(authProvider).error ?? e.toString();
      _notify(msg, isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final busy = _submitting || authState.isLoading;
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Material(
              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Create your own account with email + password.\n'
                  'Phone is optional. Check the attestation box before Create Account.\n'
                  'Shared device? Sign out first (or use a private window).',
                  style: TextStyle(fontSize: 13, height: 1.35),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Explicit mode buttons (more reliable than SegmentedButton on some web browsers)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy
                        ? null
                        : () {
                            setState(() {
                              _isLogin = true;
                              _phoneOtpSent = false;
                            });
                            ref.read(authProvider.notifier).clearError();
                          },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _isLogin
                          ? theme.colorScheme.primaryContainer
                          : null,
                    ),
                    child: const Text('Sign In'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy
                        ? null
                        : () {
                            setState(() {
                              _isLogin = false;
                              _phoneOtpSent = false;
                            });
                            ref.read(authProvider.notifier).clearError();
                          },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !_isLogin
                          ? theme.colorScheme.primaryContainer
                          : null,
                    ),
                    child: const Text('Create Account'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (authState.error != null) ...[
              _StatusBanner(message: authState.error!, isError: true),
              const SizedBox(height: 12),
            ] else if (authState.info != null) ...[
              _StatusBanner(message: authState.info!, isError: false),
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
                  enabled: !busy,
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
                  enabled: !busy,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    hintText: '+1 555 123 4567',
                    border: OutlineInputBorder(),
                    helperText: 'Leave blank for beta — SMS not required',
                  ),
                  keyboardType: TextInputType.phone,
                  enabled: !busy,
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _affirmedAttestation
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: _affirmedAttestation ? 2 : 1,
                    ),
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
                        onChanged: busy
                            ? null
                            : (val) {
                                setState(
                                  () => _affirmedAttestation = val ?? false,
                                );
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

                FilledButton(
                  onPressed: busy ? null : _handleSignup,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _affirmedAttestation
                      ? 'Ready — tap Create Account above.'
                      : '1) Check the attestation box  2) Tap Create Account',
                  style: TextStyle(
                    fontSize: 13,
                    color: _affirmedAttestation
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
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
                  enabled: !busy,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy ? null : _verifyOtp,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify Phone & Continue'),
                  ),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          setState(() {
                            _phoneOtpSent = false;
                            _otpController.clear();
                          });
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
                enabled: !busy,
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
                enabled: !busy,
                onSubmitted: (_) {
                  if (!busy) _handleLogin();
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: busy ? null : _handleLogin,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In', style: TextStyle(fontSize: 16)),
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
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push('/terms'),
              child: const Text('Privacy & standards'),
            ),
            Text(
              'Beta v0.1.8',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
