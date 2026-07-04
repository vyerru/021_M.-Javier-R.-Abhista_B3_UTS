import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/entities.dart';
import 'user_dto.dart';

part 'ticket_history_dto.g.dart';

@JsonSerializable()
class TicketHistoryDto {
  final String id;
  @JsonKey(name: 'ticket_id')
  final String ticketId;
  @JsonKey(name: 'changed_by')
  final dynamic changedByRaw;
  final String action;
  @JsonKey(name: 'from_status')
  final String? fromStatus;
  @JsonKey(name: 'to_status')
  final String? toStatus;
  @JsonKey(name: 'timestamp')
  final DateTime timestamp;

  const TicketHistoryDto({
    required this.id,
    required this.ticketId,
    required this.changedByRaw,
    required this.action,
    this.fromStatus,
    this.toStatus,
    required this.timestamp,
  });

  factory TicketHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$TicketHistoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TicketHistoryDtoToJson(this);

  String get changedById {
    if (changedByRaw is Map) {
      return (changedByRaw as Map)['id'] as String;
    }
    return changedByRaw as String;
  }

  UserDto? get nestedChangedBy {
    if (changedByRaw is Map) {
      return UserDto.fromJson(changedByRaw as Map<String, dynamic>);
    }
    return null;
  }

  TicketHistory toEntity({User? changedBy}) {
    final resolvedChangedBy = changedBy ?? nestedChangedBy?.toEntity() ?? User(
      id: changedById,
      username: '',
      fullName: 'Unknown',
      email: '',
      avatarUrl: '',
      role: UserRole.user,
      createdAt: timestamp,
    );
    return TicketHistory(
      id: id,
      ticketId: ticketId,
      changedBy: resolvedChangedBy,
      action: action,
      fromStatus: fromStatus != null
          ? TicketStatus.values.firstWhere(
              (s) => s.name == fromStatus,
              orElse: () => TicketStatus.open,
            )
          : null,
      toStatus: toStatus != null
          ? TicketStatus.values.firstWhere(
              (s) => s.name == toStatus,
              orElse: () => TicketStatus.open,
            )
          : null,
      timestamp: timestamp,
    );
  }

  static TicketHistoryDto fromEntity(TicketHistory entity) {
    return TicketHistoryDto(
      id: entity.id,
      ticketId: entity.ticketId,
      changedByRaw: entity.changedBy.id,
      action: entity.action,
      fromStatus: entity.fromStatus?.name,
      toStatus: entity.toStatus?.name,
      timestamp: entity.timestamp,
    );
  }
}
