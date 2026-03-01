import 'package:flutter/material.dart';

class BackendUrlSection extends StatelessWidget {
  const BackendUrlSection({
    super.key,
    required this.controller,
    required this.onSave,
    required this.onUseLocal,
    required this.onUseProduction,
  });

  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onUseLocal;
  final VoidCallback onUseProduction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Backend URL'),
          onSubmitted: (_) => onSave(),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(onPressed: onUseLocal, child: const Text('Use Local')),
            OutlinedButton(onPressed: onUseProduction, child: const Text('Use Production Default')),
            ElevatedButton(onPressed: onSave, child: const Text('Save URL')),
          ],
        ),
      ],
    );
  }
}
