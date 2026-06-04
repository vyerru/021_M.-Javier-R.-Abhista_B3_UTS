import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/entities.dart';

part 'ticket_dto.g.dart';

@JsonSerializable()
class TicketDto {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String category;
  @JsonKey(name: 'created_by')
  final String createdById;
  @JsonKey(name: 'assigned_to')
  final String? assignedToId;
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
    required this.createdById,
    this.assignedToId,
    this.attachmentUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketDto.fromJson(Map<String, dynamic> json) =>
      _$TicketDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TicketDtoToJson(this);

  Ticket toEntity({
    required User createdBy,
    User? assignedTo,
    List<Comment> comments = const [],
    List<TicketHistory> history = const [],
  }) {
    return Ticket(
      id: int.tryParse(id) ?? id.hashCode,
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
      createdBy: createdBy,
      assignedTo: assignedTo,
      attachmentUrls: attachmentUrls,
      comments: comments,
      history: history,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static TicketDto fromEntity(Ticket entity) {
    return TicketDto(
      id: entity.id.toString(),
      title: entity.title,
      description: entity.description,
      status: entity.status.name,
      priority: entity.priority.name,
      category: entity.category,
      createdById: entity.createdBy.id.toString(),
      assignedToId: entity.assignedTo?.id.toString(),
      attachmentUrls: entity.attachmentUrls,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
