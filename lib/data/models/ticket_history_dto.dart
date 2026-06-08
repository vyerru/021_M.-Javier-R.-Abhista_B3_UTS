import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/entities.dart';

part 'ticket_history_dto.g.dart';

@JsonSerializable()
class TicketHistoryDto {
  final String id;
  @JsonKey(name: 'ticket_id')
  final String ticketId;
  @JsonKey(name: 'changed_by')
  final String changedById;
  final String action;
  @JsonKey(name: 'from_status')
  final String? fromStatus;
  @JsonKey(name: 'to_status')
  final String? toStatus;
  final DateTime timestamp;

  const TicketHistoryDto({
    required this.id,
    required this.ticketId,
    required this.changedById,
    required this.action,
    this.fromStatus,
    this.toStatus,
    required this.timestamp,
  });

  factory TicketHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$TicketHistoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TicketHistoryDtoToJson(this);

  TicketHistory toEntity({required User changedBy}) {
    return TicketHistory(
      id: id,
      ticketId: ticketId,
      changedBy: changedBy,
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
      changedById: entity.changedBy.id,
      action: entity.action,
      fromStatus: entity.fromStatus?.name,
      toStatus: entity.toStatus?.name,
      timestamp: entity.timestamp,
    );
  }
}
