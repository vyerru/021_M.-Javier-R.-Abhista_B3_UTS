import 'package:flutter/material.dart';
import 'info_row.dart';

class TicketInfoCard extends StatelessWidget {
  final String category;
  final String createdBy;
  final String? assignedTo;
  final Color? assignedToColor;
  final String createdAt;
  final String updatedAt;

  const TicketInfoCard({
    super.key,
    required this.category,
    required this.createdBy,
    this.assignedTo,
    this.assignedToColor,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InfoRow(icon: Icons.folder_outlined, label: 'Kategori', value: category),
            const SizedBox(height: 12),
            InfoRow(icon: Icons.person_outline_rounded, label: 'Dibuat oleh', value: createdBy),
            const SizedBox(height: 12),
            InfoRow(
              icon: Icons.support_agent_rounded,
              label: 'Di-assign ke',
              value: assignedTo ?? '— Belum di-assign —',
              valueColor: assignedToColor,
            ),
            const SizedBox(height: 12),
            InfoRow(icon: Icons.schedule_rounded, label: 'Dibuat', value: createdAt),
            const SizedBox(height: 12),
            InfoRow(icon: Icons.update_rounded, label: 'Diperbarui', value: updatedAt),
          ],
        ),
      ),
    );
  }
}
