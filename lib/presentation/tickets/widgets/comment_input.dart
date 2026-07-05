import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CommentInput extends StatelessWidget {
  final bool isClosed;
  final bool isSubmitting;
  final TextEditingController controller;
  final VoidCallback? onSubmit;

  const CommentInput({
    super.key,
    required this.isClosed,
    required this.isSubmitting,
    required this.controller,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 10),
      child: Row(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSubmitting && !isClosed,
              maxLines: 4,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: isClosed ? 'Tiket sudah ditutup' : 'Tulis komentar...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: isSubmitting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : IconButton.filled(
                    onPressed: isClosed ? null : onSubmit,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: isClosed
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                          : AppTheme.accentCyan,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
