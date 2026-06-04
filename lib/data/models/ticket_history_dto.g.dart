// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_history_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketHistoryDto _$TicketHistoryDtoFromJson(Map<String, dynamic> json) =>
    TicketHistoryDto(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      changedById: json['changed_by'] as String,
      action: json['action'] as String,
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$TicketHistoryDtoToJson(TicketHistoryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticket_id': instance.ticketId,
      'changed_by': instance.changedById,
      'action': instance.action,
      'from_status': instance.fromStatus,
      'to_status': instance.toStatus,
      'timestamp': instance.timestamp.toIso8601String(),
    };
