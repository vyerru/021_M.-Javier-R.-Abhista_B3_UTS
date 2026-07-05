import '../../repositories/ticket_repository.dart';

class UpdateAttachmentUrlsUseCase {
  final TicketRepository _repository;

  UpdateAttachmentUrlsUseCase(this._repository);

  Future<void> call(String ticketId, List<String> urls) {
    return _repository.updateAttachmentUrls(ticketId, urls);
  }
}
