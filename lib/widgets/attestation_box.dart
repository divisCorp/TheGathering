import 'package:flutter/material.dart';
import 'package:the_gathering/services/auth_service.dart';

/// Reusable attestation / standards agreement checkbox.
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
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          AuthService.attestationText,
          style: const TextStyle(fontSize: 14),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
