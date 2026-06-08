import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/entities.dart';
import 'user_dto.dart';

part 'ticket_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class TicketDto {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String category;
  @JsonKey(name: 'created_by')
  final dynamic createdByRaw;
  @JsonKey(name: 'assigned_to')
  final dynamic assignedToRaw;
  @JsonKey(name: 'attachment_urls')
  final List<String> attachmentUrls;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const TicketDto({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.createdByRaw,
    this.assignedToRaw,
    this.attachmentUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get createdById {
    if (createdByRaw is Map) {
      return (createdByRaw as Map)['id'] as String;
    }
    return createdByRaw as String;
  }

  String? get assignedToId {
    if (assignedToRaw == null) return null;
    if (assignedToRaw is Map) {
      return (assignedToRaw as Map)['id'] as String;
    }
    return assignedToRaw as String?;
  }

  UserDto? get nestedCreatedBy {
    if (createdByRaw is Map) {
      return UserDto.fromJson(createdByRaw as Map<String, dynamic>);
    }
    return null;
  }

  UserDto? get nestedAssignedTo {
    if (assignedToRaw is Map) {
      return UserDto.fromJson(assignedToRaw as Map<String, dynamic>);
    }
    return null;
  }

  factory TicketDto.fromJson(Map<String, dynamic> json) =>
      _$TicketDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TicketDtoToJson(this);

  Ticket toEntity({
    User? createdBy,
    User? assignedTo,
    List<Comment> comments = const [],
    List<TicketHistory> history = const [],
  }) {
    return Ticket(
      id: id,
      title: title,
      description: description,
      status: TicketStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => TicketStatus.open,
      ),
      priority: TicketPriority.values.firstWhere(
        (p) => p.name == priority,
        orElse: () => TicketPriority.medium,
      ),
      category: category,
      createdBy: createdBy ?? nestedCreatedBy?.toEntity() ?? User(
        id: createdById,
        username: '',
        fullName: 'Unknown',
        email: '',
        avatarUrl: '',
        role: UserRole.user,
        createdAt: createdAt,
      ),
      assignedTo: assignedTo ?? nestedAssignedTo?.toEntity(),
      attachmentUrls: attachmentUrls,
      comments: comments,
      history: history,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static TicketDto fromEntity(Ticket entity) {
    return TicketDto(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      status: entity.status.name,
      priority: entity.priority.name,
      category: entity.category,
      createdByRaw: entity.createdBy.id,
      assignedToRaw: entity.assignedTo?.id,
      attachmentUrls: entity.attachmentUrls,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
