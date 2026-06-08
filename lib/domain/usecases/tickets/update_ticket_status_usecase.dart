import '../../entities/enums.dart';
import '../../entities/ticket.dart';
import '../../repositories/ticket_repository.dart';

class UpdateTicketStatusUseCase {
  final TicketRepository _repository;

  UpdateTicketStatusUseCase(this._repository);

  Future<Ticket> call(String ticketId, TicketStatus newStatus) {
    return _repository.updateTicketStatus(ticketId, newStatus);
  }
}
