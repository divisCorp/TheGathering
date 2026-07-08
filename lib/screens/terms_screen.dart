import 'package:flutter/material.dart';

/// Legal / Terms screen (standards + privacy notes).
/// Full policies to be finalized in later phase.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The Gathering', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Independent Community Tool'),
              const SizedBox(height: 16),
              const Text(
                'The Gathering is an independent community tool and is not affiliated with, '
                'endorsed by, or sponsored by The Church of Jesus Christ of Latter-day Saints.',
              ),
              const SizedBox(height: 24),
              const Text('Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text(
                'We collect the minimum data necessary. Precise home location is never persisted. '
                'All events and profiles follow data minimization principles.',
              ),
              const SizedBox(height: 16),
              const Text('Standards', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text(
                'All activities must be uplifting and comply with Church standards (Word of Wisdom, '
                'modesty, etc.). Violations result in removal.',
              ),
              const SizedBox(height: 32),
              Text(
                'Full Privacy Policy and Terms of Service will be finalized before beta (PR10).',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
