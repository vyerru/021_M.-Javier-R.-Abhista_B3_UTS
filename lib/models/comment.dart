import 'user.dart';

/// Model data untuk komentar / balasan pada sebuah tiket.
class Comment {
  final int id;
  final int ticketId;
  final User author;
  final String message;
  final List<String> attachmentUrls; // URL lampiran opsional
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.ticketId,
    required this.author,
    required this.message,
    this.attachmentUrls = const [],
    required this.createdAt,
  });

  /// Membuat salinan [Comment] dengan nilai yang diperbarui.
  Comment copyWith({
    int? id,
    int? ticketId,
    User? author,
    String? message,
    List<String>? attachmentUrls,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      author: author ?? this.author,
      message: message ?? this.message,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Comment(id: $id, ticketId: $ticketId, author: ${author.username})';
}