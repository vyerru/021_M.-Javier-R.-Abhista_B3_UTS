import '../../entities/ticket.dart';
import '../../repositories/ticket_repository.dart';

class AssignTicketUseCase {
  final TicketRepository _repository;

  AssignTicketUseCase(this._repository);

  Future<Ticket> call(String ticketId, String assigneeId) {
    return _repository.assignTicket(ticketId, assigneeId);
  }
}
