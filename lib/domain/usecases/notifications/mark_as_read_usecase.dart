import '../../repositories/notification_repository.dart';

class MarkAsReadUseCase {
  final NotificationRepository _repository;

  MarkAsReadUseCase(this._repository);

  Future<void> call(String notificationId) => _repository.markAsRead(notificationId);
}
