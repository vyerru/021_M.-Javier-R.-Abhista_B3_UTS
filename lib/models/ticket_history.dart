import 'enums.dart';
import 'user.dart';

/// Merepresentasikan satu entri perubahan dalam riwayat sebuah tiket.
///
/// Setiap kali status atau assignee tiket berubah, entri baru ditambahkan.
class TicketHistory {
  final int id;
  final int ticketId;
  final User changedBy;
  final String action; // Deskripsi aksi, mis. "Status changed to In Progress"
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

  /// Membuat salinan [TicketHistory] dengan nilai yang diperbarui.
  TicketHistory copyWith({
    int? id,
    int? ticketId,
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