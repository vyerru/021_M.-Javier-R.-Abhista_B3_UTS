import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/entities.dart';
import 'user_dto.dart';

part 'comment_dto.g.dart';

@JsonSerializable(explicitToJson: true)
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
  @JsonKey(name: 'author', includeToJson: false)
  final UserDto? nestedAuthor;

  const CommentDto({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.message,
    this.attachmentUrls = const [],
    required this.createdAt,
    this.nestedAuthor,
  });

  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CommentDtoToJson(this);

  Comment toEntity({User? author}) {
    final resolvedAuthor = author ??
        nestedAuthor?.toEntity() ??
        User(
          id: authorId,
          username: '',
          fullName: 'Unknown',
          email: '',
          avatarUrl: '',
          role: UserRole.user,
          createdAt: createdAt,
        );
    return Comment(
      id: id,
      ticketId: ticketId,
      author: resolvedAuthor,
      message: message,
      attachmentUrls: attachmentUrls,
      createdAt: createdAt,
    );
  }

  static CommentDto fromEntity(Comment entity) {
    return CommentDto(
      id: entity.id,
      ticketId: entity.ticketId,
      authorId: entity.author.id,
      message: entity.message,
      attachmentUrls: entity.attachmentUrls,
      createdAt: entity.createdAt,
    );
  }
}
