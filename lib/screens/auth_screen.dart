import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_gathering/providers/auth_provider.dart';
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

  Future<void> _handleSignup() async {
    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.clearError();

    try {
      if (!_affirmedAttestation) {
        throw Exception('Please affirm the membership attestation to continue.');
      }

      await authNotifier.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        affirmedAttestation: _affirmedAttestation,
      );

      setState(() {
        _phoneOtpSent = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent to your phone. Enter OTP below.')),
        );
      }
    } catch (e) {
      // error in provider
    }
  }

  Future<void> _verifyOtp() async {
    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.clearError();

    try {
      await authNotifier.verifyPhone(
        phone: _phoneController.text.trim(),
        otp: _otpController.text.trim(),
      );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      // error in provider
    }
  }

  Future<void> _handleLogin() async {
    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.clearError();

    try {
      await authNotifier.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      // error in provider
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final isLoading = authState.isLoading;
    final error = authState.error;

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

            // Toggle Login / Sign Up
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
                });
                ref.read(authProvider.notifier).clearError();
              },
            ),
            const SizedBox(height: 24),

            if (!_isLogin) ...[
              // Sign up fields
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (for verification)',
                  hintText: '+1 555 123 4567',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Mandatory Self-Attestation (exact per design)
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
                      onChanged: (val) => setState(() => _affirmedAttestation = val ?? false),
                      title: const Text('I affirm the above statement'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

              if (_phoneOtpSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'Enter SMS Verification Code',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _verifyOtp,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Verify Phone & Continue'),
                ),
              ] else ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _handleSignup,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Account & Send Verification Code'),
                ),
              ],
            ] else ...[
              // Login
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Sign In'),
              ),
            ],

            if (error != null) ...[
              const SizedBox(height: 16),
              Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
