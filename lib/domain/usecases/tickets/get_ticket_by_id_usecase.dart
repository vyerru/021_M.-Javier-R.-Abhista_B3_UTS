import '../../entities/ticket.dart';
import '../../repositories/ticket_repository.dart';

class GetTicketByIdUseCase {
  final TicketRepository _repository;

  GetTicketByIdUseCase(this._repository);

  Future<Ticket> call(String id) => _repository.getTicketById(id);
}
