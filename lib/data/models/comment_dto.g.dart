// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentDto _$CommentDtoFromJson(Map<String, dynamic> json) => CommentDto(
  id: json['id'] as String,
  ticketId: json['ticket_id'] as String,
  authorId: json['author_id'] as String,
  message: json['message'] as String,
  attachmentUrls:
      (json['attachment_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$CommentDtoToJson(CommentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticket_id': instance.ticketId,
      'author_id': instance.authorId,
      'message': instance.message,
      'attachment_urls': instance.attachmentUrls,
      'created_at': instance.createdAt.toIso8601String(),
    };
