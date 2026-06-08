import '../../entities/user.dart';
import '../../repositories/ticket_repository.dart';

class GetHelpdeskUsersUseCase {
  final TicketRepository _repository;

  GetHelpdeskUsersUseCase(this._repository);

  Future<List<User>> call() => _repository.getHelpdeskUsers();
}
