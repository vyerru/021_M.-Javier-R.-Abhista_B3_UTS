import '../../entities/ticket.dart';
import '../../repositories/ticket_repository.dart';

class CreateTicketUseCase {
  final TicketRepository _repository;

  CreateTicketUseCase(this._repository);

  Future<Ticket> call(Ticket ticket) => _repository.createTicket(ticket);
}
