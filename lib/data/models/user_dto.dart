import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/entities.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserDto {
  final String id;
  final String username;
  final String password;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String email;
  @JsonKey(name: 'avatar_url')
  final String avatarUrl;
  final String role;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const UserDto({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);

  User toEntity() {
    return User(
      id: int.tryParse(id) ?? id.hashCode,
      username: username,
      password: password,
      fullName: fullName,
      email: email,
      avatarUrl: avatarUrl,
      role: UserRole.values.firstWhere(
        (r) => r.name == role,
        orElse: () => UserRole.user,
      ),
      createdAt: createdAt,
    );
  }

  static UserDto fromEntity(User entity) {
    return UserDto(
      id: entity.id.toString(),
      username: entity.username,
      password: entity.password,
      fullName: entity.fullName,
      email: entity.email,
      avatarUrl: entity.avatarUrl,
      role: entity.role.name,
      createdAt: entity.createdAt,
    );
  }
}
