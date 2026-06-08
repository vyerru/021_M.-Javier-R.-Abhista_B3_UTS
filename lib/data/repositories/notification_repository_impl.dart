import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/supabase_notification_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final SupabaseNotificationDataSource _dataSource;

  NotificationRepositoryImpl(this._dataSource);

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    final dtoList = await _dataSource.getNotifications(userId);
    return dtoList.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    return _dataSource.getUnreadCount(userId);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _dataSource.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await _dataSource.markAllAsRead(userId);
  }

}
