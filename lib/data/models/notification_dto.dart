import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/entities.dart';

part 'notification_dto.g.dart';

@JsonSerializable()
class NotificationDto {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String title;
  final String message;
  @JsonKey(name: 'ticket_id')
  final String? ticketId;
  @JsonKey(name: 'ticket_title')
  final String? ticketTitle;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const NotificationDto({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.ticketId,
    this.ticketTitle,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationDtoToJson(this);

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      ticketId: ticketId,
      ticketTitle: ticketTitle,
      isRead: isRead,
      createdAt: createdAt,
    );
  }

  static NotificationDto fromEntity(AppNotification entity) {
    return NotificationDto(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      message: entity.message,
      ticketId: entity.ticketId,
      ticketTitle: entity.ticketTitle,
      isRead: entity.isRead,
      createdAt: entity.createdAt,
    );
  }
}
