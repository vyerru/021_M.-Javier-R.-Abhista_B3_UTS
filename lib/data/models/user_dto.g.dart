// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: json['id'] as String,
  username: json['username'] as String,
  fullName: json['full_name'] as String,
  email: json['email'] as String,
  avatarUrl: json['avatar_url'] as String,
  role: json['role'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'full_name': instance.fullName,
  'email': instance.email,
  'avatar_url': instance.avatarUrl,
  'role': instance.role,
  'created_at': instance.createdAt.toIso8601String(),
};
