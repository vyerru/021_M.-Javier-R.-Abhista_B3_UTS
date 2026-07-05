import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TicketAttachments extends StatelessWidget {
  final List<String> urls;
  final void Function(String url)? onImageTap;

  const TicketAttachments({super.key, required this.urls, this.onImageTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (urls.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 6,
              children: [
                Icon(Icons.attach_file_rounded, size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                Text('Lampiran (${urls.length})',
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: urls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final url = urls[index];
                  final isImage = RegExp(r'\.(jpg|jpeg|png|gif|webp)(\?|$)').hasMatch(url);

                  return GestureDetector(
                    onTap: isImage && onImageTap != null ? () => onImageTap!(url) : null,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: isImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(url, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded)),
                            )
                          : Center(
                              child: Icon(
                                url.contains('.pdf')
                                    ? Icons.picture_as_pdf_rounded
                                    : Icons.insert_drive_file_rounded,
                                size: 32,
                                color: AppTheme.accentCyan.withValues(alpha: 0.6),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
