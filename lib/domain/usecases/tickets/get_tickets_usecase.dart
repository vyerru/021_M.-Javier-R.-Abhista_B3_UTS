import '../../entities/enums.dart';
import '../../entities/ticket.dart';
import '../../repositories/ticket_repository.dart';

class GetTicketsUseCase {
  final TicketRepository _repository;

  GetTicketsUseCase(this._repository);

  Future<List<Ticket>> call({TicketStatus? statusFilter, int page = 0, int pageSize = 20}) {
    return _repository.getTickets(statusFilter: statusFilter, page: page, pageSize: pageSize);
  }
}
