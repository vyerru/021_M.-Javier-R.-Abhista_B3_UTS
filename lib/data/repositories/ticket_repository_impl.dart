import '../../domain/entities/comment.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/supabase_comment_data_source.dart';
import '../datasources/supabase_ticket_data_source.dart';
import '../models/user_dto.dart';

class TicketRepositoryImpl implements TicketRepository {
  final SupabaseTicketDataSource _ticketDataSource;
  final SupabaseCommentDataSource _commentDataSource;

  TicketRepositoryImpl(
    this._ticketDataSource,
    this._commentDataSource,
  );

  @override
  Future<List<Ticket>> getTickets({TicketStatus? statusFilter}) async {
    final dtoList = await _ticketDataSource.getTickets(
      statusFilter: statusFilter?.name,
    );

    final tickets = <Ticket>[];
    for (final dto in dtoList) {
      final comments = await _fetchComments(dto.id);
      tickets.add(dto.toEntity(comments: comments));
    }
    return tickets;
  }

  @override
  Future<Ticket> getTicketById(String id) async {
    final dto = await _ticketDataSource.getTicketById(id);
    final comments = await _fetchComments(dto.id);
    return dto.toEntity(comments: comments);
  }

  @override
  Future<Ticket> createTicket(Ticket ticket) async {
    final dto = await _ticketDataSource.createTicket({
      'title': ticket.title,
      'description': ticket.description,
      'status': ticket.status.name,
      'priority': ticket.priority.name,
      'category': ticket.category,
      'created_by': ticket.createdBy.id,
      'assigned_to': null,
      'attachment_urls': ticket.attachmentUrls,
    });

    return dto.toEntity(
      createdBy: ticket.createdBy,
      comments: ticket.comments,
      history: ticket.history,
    );
  }

  @override
  Future<Ticket> updateTicketStatus(String ticketId, TicketStatus newStatus) async {
    final dto = await _ticketDataSource.updateStatus(
      ticketId,
      newStatus.name,
    );
    final comments = await _fetchComments(dto.id);

    final changedBy = _ticketDataSource.client.auth.currentUser?.id ?? dto.createdById;
    await _ticketDataSource.addHistory({
      'ticket_id': ticketId,
      'changed_by': changedBy,
      'action': 'Status changed to ${newStatus.label}',
      'to_status': newStatus.name,
    });

    return dto.toEntity(comments: comments);
  }

  @override
  Future<Ticket> assignTicket(String ticketId, String assigneeId) async {
    final dto = await _ticketDataSource.assignTicket(
      ticketId,
      assigneeId,
    );
    final comments = await _fetchComments(dto.id);
    final assignedTo = dto.nestedAssignedTo?.toEntity();
    final changedBy = _ticketDataSource.client.auth.currentUser?.id ?? dto.createdById;
    await _ticketDataSource.addHistory({
      'ticket_id': ticketId,
      'changed_by': changedBy,
      'action': 'Assigned to ${assignedTo?.fullName ?? 'unknown'}',
    });

    return dto.toEntity(comments: comments);
  }

  @override
  Future<Map<String, int>> getStatistics({String? userId}) async {
    return _ticketDataSource.getStatistics(userId: userId);
  }

  @override
  Future<List<User>> getHelpdeskUsers() async {
    final data = await _ticketDataSource.getHelpdeskUsers();
    return data
        .map((json) => UserDto.fromJson(json).toEntity())
        .toList();
  }

  Future<List<Comment>> _fetchComments(String ticketId) async {
    try {
      final dtoList = await _commentDataSource.getComments(ticketId);
      return dtoList.map((dto) => dto.toEntity()).toList();
    } catch (_) {
      return [];
    }
  }
}
