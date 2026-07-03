import 'package:flutter/material.dart';
import 'package:the_gathering/services/auth_service.dart';

/// Reusable attestation widget for future screens.
class AttestationBox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const AttestationBox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Membership Attestation (Required)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(AuthService.attestationText, style: const TextStyle(fontSize: 13)),
          CheckboxListTile(
            value: value,
            onChanged: onChanged,
            title: const Text('I affirm the above statement'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
