import '../entities/ticket.dart';
import '../entities/user.dart';
import '../entities/enums.dart';

abstract class TicketRepository {
  Future<List<Ticket>> getTickets({TicketStatus? statusFilter});
  Future<Ticket> getTicketById(String id);
  Future<Ticket> createTicket(Ticket ticket);
  Future<Ticket> updateTicketStatus(String ticketId, TicketStatus newStatus);
  Future<Ticket> assignTicket(String ticketId, String assigneeId);
  Future<Map<String, int>> getStatistics({String? userId});
  Future<List<User>> getHelpdeskUsers();
}
