import 'package:flutter/material.dart';

/// Legal / Terms screen (standards + privacy notes for beta).
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & standards')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'The Gathering',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text('Independent community tool (beta)', style: TextStyle(color: muted)),
          const SizedBox(height: 16),
          const Text(
            'The Gathering is an independent community tool and is not affiliated with, '
            'endorsed by, or sponsored by The Church of Jesus Christ of Latter-day Saints.',
          ),
          const SizedBox(height: 24),
          Text('Privacy', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'We collect the minimum data needed to run the app: account email, '
            'optional phone, profile fields you choose (name, bio, city, interests, photo), '
            'and events/RSVPs you create.\n\n'
            'Precise home GPS is not stored on your profile. Location is used ephemerally '
            'to discover nearby activities and to pin event locations when you allow it.\n\n'
            'You can request account deletion by emailing the beta operator '
            '(see Profile → Send beta feedback).',
          ),
          const SizedBox(height: 24),
          Text('Community standards', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Activities must be wholesome and aligned with Church standards, including '
            'the Word of Wisdom and modest conduct. This is not a dating app: '
            'romantic matching, pickup culture, and immodest themes are not allowed.\n\n'
            'Prohibited event content includes alcohol, tobacco, vaping, illicit substances, '
            'and dating/hookup framing. Report violations via event ⋮ → Report activity.\n\n'
            'False reports or abuse of the community may result in account removal.',
          ),
          const SizedBox(height: 24),
          Text('Safety', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Meet in public or appropriate venues when possible. '
            'Use RSVP and host judgment. The app provides tools; you remain responsible '
            'for personal safety and local laws.',
          ),
          const SizedBox(height: 24),
          Text(
            'Full Privacy Policy and Terms of Service will be finalized before public store launch. '
            'This summary applies during closed beta.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
