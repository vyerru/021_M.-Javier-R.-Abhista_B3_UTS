import 'comment.dart';
import 'enums.dart';
import 'ticket_history.dart';
import 'user.dart';

/// Model data utama untuk tiket helpdesk.
class Ticket {
  final int id;
  final String title;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final String category; // Mis. "Hardware", "Software", "Network"
  final User createdBy;
  final User? assignedTo; // Null jika belum di-assign
  final List<String> attachmentUrls;
  final List<Comment> comments;
  final List<TicketHistory> history;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.createdBy,
    this.assignedTo,
    this.attachmentUrls = const [],
    this.comments = const [],
    this.history = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Membuat salinan [Ticket] dengan nilai yang diperbarui.
  Ticket copyWith({
    int? id,
    String? title,
    String? description,
    TicketStatus? status,
    TicketPriority? priority,
    String? category,
    User? createdBy,
    User? assignedTo,
    List<String>? attachmentUrls,
    List<Comment>? comments,
    List<TicketHistory>? history,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      comments: comments ?? this.comments,
      history: history ?? this.history,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Ticket(id: $id, title: $title, status: ${status.label})';
}