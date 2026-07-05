import 'package:flutter/material.dart';

class StaffActionsCard extends StatelessWidget {
  final bool showStatusButton;
  final String statusButtonLabel;
  final VoidCallback? onStatusTap;
  final bool showAssignButton;
  final VoidCallback? onAssignTap;
  final bool isSubmitting;

  const StaffActionsCard({
    super.key,
    required this.showStatusButton,
    this.statusButtonLabel = 'Ubah Status',
    this.onStatusTap,
    required this.showAssignButton,
    this.onAssignTap,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            if (showStatusButton)
              OutlinedButton.icon(
                onPressed: isSubmitting ? null : onStatusTap,
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: Text(statusButtonLabel),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              ),
            if (showAssignButton)
              ElevatedButton.icon(
                onPressed: isSubmitting ? null : onAssignTap,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Assign'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
              ),
          ],
        ),
      ),
    );
  }
}
