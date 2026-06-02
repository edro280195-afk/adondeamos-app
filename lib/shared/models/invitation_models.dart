import 'package:adondeamos/core/api/json_helpers.dart';

class Invitation {
  const Invitation({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.invitedBy,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String invitedBy;
  final String status;
  final String createdAt;
  final String? respondedAt;

  bool get isPending => status == 'pending';

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: safeStr(json['id']),
      groupId: safeStr(json['groupId']),
      groupName: safeStr(json['groupName']),
      invitedBy: safeStr(json['invitedBy']),
      status: safeStr(json['status']),
      createdAt: safeStr(json['createdAt']),
      respondedAt: safeStrOrNull(json['respondedAt']),
    );
  }
}
