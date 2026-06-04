import '../entities/ticket.dart';
import '../entities/user.dart';
import '../entities/enums.dart';

abstract class TicketRepository {
  Future<List<Ticket>> getTickets({TicketStatus? statusFilter});
  Future<Ticket> getTicketById(int id);
  Future<Ticket> createTicket(Ticket ticket);
  Future<Ticket> updateTicketStatus(int ticketId, TicketStatus newStatus);
  Future<Ticket> assignTicket(int ticketId, int assigneeId);
  Future<Map<String, int>> getStatistics({int? userId});
  Future<List<User>> getHelpdeskUsers();
}
