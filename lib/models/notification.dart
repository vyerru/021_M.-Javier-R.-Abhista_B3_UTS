class AppNotification {
  final int id;
  final int userId;
  final String title;
  final String message;
  final int? ticketId;
  final String? ticketTitle;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.ticketId,
    this.ticketTitle,
    this.isRead = false,
    required this.createdAt,
  });

  AppNotification copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    int? ticketId,
    String? ticketTitle,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      ticketId: ticketId ?? this.ticketId,
      ticketTitle: ticketTitle ?? this.ticketTitle,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
