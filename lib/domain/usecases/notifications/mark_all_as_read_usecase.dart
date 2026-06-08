import '../../repositories/notification_repository.dart';

class MarkAllAsReadUseCase {
  final NotificationRepository _repository;

  MarkAllAsReadUseCase(this._repository);

  Future<void> call(String userId) => _repository.markAllAsRead(userId);
}
