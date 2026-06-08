import '../../repositories/ticket_repository.dart';

class GetStatisticsUseCase {
  final TicketRepository _repository;

  GetStatisticsUseCase(this._repository);

  Future<Map<String, int>> call({String? userId}) {
    return _repository.getStatistics(userId: userId);
  }
}
