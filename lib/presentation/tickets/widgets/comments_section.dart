import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/comment.dart';
import '../../../domain/entities/user.dart';

class CommentsSection extends StatelessWidget {
  final List<Comment> comments;
  final User? currentUser;

  const CommentsSection({super.key, required this.comments, this.currentUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 2),
          child: Text('Komentar (${comments.length})',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.2)),
        ),
        if (comments.isEmpty)
          Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 36,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.25)),
                    const SizedBox(height: 8),
                    Text('Belum ada komentar',
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  ],
                ),
              ),
            ),
          )
        else
          ...comments.map((comment) {
            final isMe = comment.author.id == currentUser?.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                color: isMe ? AppTheme.accentCyan.withValues(alpha: 0.07) : null,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: comment.author.avatarUrl.isNotEmpty
                                ? NetworkImage(comment.author.avatarUrl) : null,
                            child: comment.author.avatarUrl.isEmpty
                                ? Text(comment.author.fullName.isNotEmpty
                                    ? comment.author.fullName[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 10)) : null,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  spacing: 6,
                                  children: [
                                    Text(comment.author.fullName,
                                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentCyan.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(comment.author.role.label,
                                          style: const TextStyle(
                                            fontSize: 10, color: AppTheme.accentCyan, fontWeight: FontWeight.w600,
                                          )),
                                    ),
                                  ],
                                ),
                                Text(_formatDateTime(comment.createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(comment.message,
                          maxLines: 5, overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year}, $h:$m';
  }
}
