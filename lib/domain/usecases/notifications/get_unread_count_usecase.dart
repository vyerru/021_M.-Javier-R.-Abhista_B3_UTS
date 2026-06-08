import '../../repositories/notification_repository.dart';

class GetUnreadCountUseCase {
  final NotificationRepository _repository;

  GetUnreadCountUseCase(this._repository);

  Future<int> call(String userId) => _repository.getUnreadCount(userId);
}
