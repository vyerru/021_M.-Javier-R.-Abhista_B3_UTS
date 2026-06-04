import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/entities.dart';

part 'comment_dto.g.dart';

@JsonSerializable()
class CommentDto {
  final String id;
  @JsonKey(name: 'ticket_id')
  final String ticketId;
  @JsonKey(name: 'author_id')
  final String authorId;
  final String message;
  @JsonKey(name: 'attachment_urls')
  final List<String> attachmentUrls;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const CommentDto({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.message,
    this.attachmentUrls = const [],
    required this.createdAt,
  });

  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CommentDtoToJson(this);

  Comment toEntity({required User author}) {
    return Comment(
      id: int.tryParse(id) ?? id.hashCode,
      ticketId: int.tryParse(ticketId) ?? ticketId.hashCode,
      author: author,
      message: message,
      attachmentUrls: attachmentUrls,
      createdAt: createdAt,
    );
  }

  static CommentDto fromEntity(Comment entity) {
    return CommentDto(
      id: entity.id.toString(),
      ticketId: entity.ticketId.toString(),
      authorId: entity.author.id.toString(),
      message: entity.message,
      attachmentUrls: entity.attachmentUrls,
      createdAt: entity.createdAt,
    );
  }
}
