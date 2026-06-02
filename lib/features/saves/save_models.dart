import 'package:adondeamos/core/api/json_helpers.dart';
import 'package:adondeamos/features/places/place_models.dart';

class PlaceSave {
  const PlaceSave({
    required this.id,
    required this.place,
    required this.sourceNetwork,
    required this.visibility,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.sourceUrl,
    this.thumbnailUrl,
    this.note,
    this.visitedAt,
  });

  final String id;
  final Place place;
  final String sourceNetwork;
  final String? sourceUrl;
  final String? thumbnailUrl;
  final String? note;
  final String visibility;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? visitedAt;

  bool get isPending => status == 'pending';
  bool get isVisited => status == 'visited';

  factory PlaceSave.fromJson(Map<String, dynamic> json) {
    return PlaceSave(
      id: safeStr(json['id']),
      place: Place.fromJson(json['place'] as Map<String, dynamic>),
      sourceNetwork: safeStr(json['sourceNetwork']),
      sourceUrl: safeStrOrNull(json['sourceUrl']),
      thumbnailUrl: safeStrOrNull(json['thumbnailUrl']),
      note: safeStrOrNull(json['note']),
      visibility: safeStr(json['visibility']),
      status: safeStr(json['status']),
      createdAt: safeStr(json['createdAt']),
      updatedAt: safeStr(json['updatedAt']),
      visitedAt: safeStrOrNull(json['visitedAt']),
    );
  }
}
