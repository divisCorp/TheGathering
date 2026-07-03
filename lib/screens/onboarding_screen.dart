import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

/// Onboarding for The Gathering (PR1 skeleton)
/// - Values / 4 areas intro
/// - Location permission explanation (ephemeral use only)
/// - Privacy notes
/// - Leads to limited home (full profile/photo in PR2)
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _requestLocation(BuildContext context) async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      // In real app, store coarse preference only
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location access granted (used ephemerally for discovery).')),
        );
        context.go('/home'); // Main shell (Profile tab available for activation in PR2)
      }
    } else {
      // Allow proceeding with manual city for privacy
      if (context.mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to The Gathering')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find uplifting activities with people who share your faith.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            const Text(
              'The Gathering helps you discover and create wholesome activities aligned with gospel principles.',
            ),
            const SizedBox(height: 24),

            const Text('Activities are tagged across four areas of growth:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('Spiritual')),
                Chip(label: Text('Social')),
                Chip(label: Text('Physical')),
                Chip(label: Text('Intellectual')),
              ],
            ),

            const Spacer(),

            // Location permission explanation per design
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Location Access', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'We use your location only to show activities within a distance you choose. '
                    'Precise location is never stored in your profile. You can use a city instead.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _requestLocation(context),
                    child: const Text('Allow "When In Use" Location'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Use City Instead (recommended for privacy)'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Skip for now → (set up Profile in the app)'),
            ),
          ],
        ),
      ),
    );
  }
}
