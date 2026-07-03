import 'package:flutter/material.dart';

/// Stub Privacy Policy and Terms screen (PR1 legal requirement).
/// Full content and legal review in PR10.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The Gathering', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Independent Community Tool'),
              SizedBox(height: 16),
              Text(
                'The Gathering is an independent community tool and is not affiliated with, '
                'endorsed by, or sponsored by The Church of Jesus Christ of Latter-day Saints.',
              ),
              SizedBox(height: 24),
              Text('Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                'We collect the minimum data necessary. Precise home location is never persisted. '
                'All events and profiles follow data minimization principles.',
              ),
              SizedBox(height: 16),
              Text('Standards', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                'All activities must be uplifting and comply with Church standards (Word of Wisdom, '
                'modesty, etc.). Violations result in removal.',
              ),
              SizedBox(height: 32),
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
