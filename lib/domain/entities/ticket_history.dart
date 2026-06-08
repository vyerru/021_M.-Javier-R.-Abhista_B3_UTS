import 'enums.dart';
import 'user.dart';

class TicketHistory {
  final String id;
  final String ticketId;
  final User changedBy;
  final String action;
  final TicketStatus? fromStatus;
  final TicketStatus? toStatus;
  final DateTime timestamp;

  const TicketHistory({
    required this.id,
    required this.ticketId,
    required this.changedBy,
    required this.action,
    this.fromStatus,
    this.toStatus,
    required this.timestamp,
  });

  TicketHistory copyWith({
    String? id,
    String? ticketId,
    User? changedBy,
    String? action,
    TicketStatus? fromStatus,
    TicketStatus? toStatus,
    DateTime? timestamp,
  }) {
    return TicketHistory(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      changedBy: changedBy ?? this.changedBy,
      action: action ?? this.action,
      fromStatus: fromStatus ?? this.fromStatus,
      toStatus: toStatus ?? this.toStatus,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() =>
      'TicketHistory(id: $id, ticketId: $ticketId, action: $action)';
}
