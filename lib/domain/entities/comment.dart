import 'user.dart';

class Comment {
  final String id;
  final String ticketId;
  final User author;
  final String message;
  final List<String> attachmentUrls;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.ticketId,
    required this.author,
    required this.message,
    this.attachmentUrls = const [],
    required this.createdAt,
  });

  Comment copyWith({
    String? id,
    String? ticketId,
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
