import '../entities/notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications(int userId);
  Future<int> getUnreadCount(int userId);
  Future<void> markAsRead(int notificationId);
  Future<void> markAllAsRead(int userId);
}
