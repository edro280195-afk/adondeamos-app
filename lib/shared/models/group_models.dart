import 'package:adondeamos/core/api/json_helpers.dart';

class Group {
  const Group({
    required this.id,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String role;
  final String createdAt;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: safeStr(json['id']),
      name: safeStr(json['name']),
      role: safeStr(json['role']),
      createdAt: safeStr(json['createdAt']),
    );
  }
}

class GroupMember {
  const GroupMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  final String userId;
  final String name;
  final String email;
  final String role;
  final String joinedAt;

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: safeStr(json['userId']),
      name: safeStr(json['name']),
      email: safeStr(json['email']),
      role: safeStr(json['role']),
      joinedAt: safeStr(json['joinedAt']),
    );
  }
}

class GroupDetail {
  const GroupDetail({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.members,
  });

  final String id;
  final String name;
  final String createdAt;
  final List<GroupMember> members;

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    return GroupDetail(
      id: safeStr(json['id']),
      name: safeStr(json['name']),
      createdAt: safeStr(json['createdAt']),
      members: (json['members'] as List<dynamic>)
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
