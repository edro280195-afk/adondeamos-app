import 'package:adondeamos/core/api/json_helpers.dart';
import 'package:adondeamos/features/places/place_models.dart';

class Vote {
  const Vote({
    required this.userId,
    required this.isYes,
    required this.createdAt,
  });

  final String userId;
  final bool isYes;
  final String createdAt;

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      userId: safeStr(json['userId']),
      isYes: json['isYes'] as bool,
      createdAt: safeStr(json['createdAt']),
    );
  }
}

class DecisionOption {
  const DecisionOption({
    required this.id,
    required this.place,
    required this.votes,
    required this.isMatch,
  });

  final String id;
  final Place place;
  final List<Vote> votes;
  final bool isMatch;

  factory DecisionOption.fromJson(Map<String, dynamic> json) {
    return DecisionOption(
      id: safeStr(json['id']),
      place: Place.fromJson(json['place'] as Map<String, dynamic>),
      votes: (json['votes'] as List<dynamic>)
          .map((v) => Vote.fromJson(v as Map<String, dynamic>))
          .toList(),
      isMatch: json['isMatch'] as bool,
    );
  }
}

class Decision {
  const Decision({
    required this.id,
    required this.createdBy,
    required this.createdAt,
    required this.participants,
    required this.options,
    required this.matchedPlaceIds,
    this.groupId,
    this.context,
  });

  final String id;
  final String? groupId;
  final String createdBy;
  final String? context;
  final String createdAt;
  final List<String> participants;
  final List<DecisionOption> options;
  final List<String> matchedPlaceIds;

  bool get hasMatch => matchedPlaceIds.isNotEmpty;

  factory Decision.fromJson(Map<String, dynamic> json) {
    return Decision(
      id: safeStr(json['id']),
      groupId: safeStrOrNull(json['groupId']),
      createdBy: safeStr(json['createdBy']),
      context: safeStrOrNull(json['context']),
      createdAt: safeStr(json['createdAt']),
      participants: (json['participants'] as List<dynamic>)
          .map((p) => safeStr(p))
          .toList(),
      options: (json['options'] as List<dynamic>)
          .map((o) => DecisionOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      matchedPlaceIds: (json['matchedPlaceIds'] as List<dynamic>)
          .map((id) => safeStr(id))
          .toList(),
    );
  }
}
