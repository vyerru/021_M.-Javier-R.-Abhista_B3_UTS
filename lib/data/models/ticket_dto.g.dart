// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketDto _$TicketDtoFromJson(Map<String, dynamic> json) => TicketDto(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  status: json['status'] as String,
  priority: json['priority'] as String,
  category: json['category'] as String,
  createdById: json['created_by'] as String,
  assignedToId: json['assigned_to'] as String?,
  attachmentUrls:
      (json['attachment_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$TicketDtoToJson(TicketDto instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'status': instance.status,
  'priority': instance.priority,
  'category': instance.category,
  'created_by': instance.createdById,
  'assigned_to': instance.assignedToId,
  'attachment_urls': instance.attachmentUrls,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
