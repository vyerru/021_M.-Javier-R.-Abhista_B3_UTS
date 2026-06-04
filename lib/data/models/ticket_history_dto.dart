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
    TicketStatus? from;
    if (fromStatus != null) {
      from = TicketStatus.values.firstWhere(
        (s) => s.name == fromStatus,
        orElse: () => TicketStatus.open,
      );
    }
    TicketStatus? to;
    if (toStatus != null) {
      to = TicketStatus.values.firstWhere(
        (s) => s.name == toStatus,
        orElse: () => TicketStatus.open,
      );
    }
    return TicketHistory(
      id: int.tryParse(id) ?? id.hashCode,
      ticketId: int.tryParse(ticketId) ?? ticketId.hashCode,
      changedBy: changedBy,
      action: action,
      fromStatus: from,
      toStatus: to,
      timestamp: timestamp,
    );
  }

  static TicketHistoryDto fromEntity(TicketHistory entity) {
    return TicketHistoryDto(
      id: entity.id.toString(),
      ticketId: entity.ticketId.toString(),
      changedById: entity.changedBy.id.toString(),
      action: entity.action,
      fromStatus: entity.fromStatus?.name,
      toStatus: entity.toStatus?.name,
      timestamp: entity.timestamp,
    );
  }
}
