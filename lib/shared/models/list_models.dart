import 'package:adondeamos/core/api/json_helpers.dart';
import 'package:adondeamos/features/saves/save_models.dart';

class PlaceList {
  const PlaceList({
    required this.id,
    required this.name,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
    this.groupId,
  });

  final String id;
  final String name;
  final String? groupId;
  final String visibility;
  final String createdAt;
  final String updatedAt;

  factory PlaceList.fromJson(Map<String, dynamic> json) {
    return PlaceList(
      id: safeStr(json['id']),
      name: safeStr(json['name']),
      groupId: safeStrOrNull(json['groupId']),
      visibility: safeStr(json['visibility']),
      createdAt: safeStr(json['createdAt']),
      updatedAt: safeStr(json['updatedAt']),
    );
  }
}

class ListItem {
  const ListItem({
    required this.save,
    required this.position,
    required this.addedAt,
    this.addedBy,
  });

  final PlaceSave save;
  final int position;
  final String addedAt;
  final String? addedBy;

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      save: PlaceSave.fromJson(json['save'] as Map<String, dynamic>),
      position: (json['position'] as num).toInt(),
      addedAt: safeStr(json['addedAt']),
      addedBy: safeStrOrNull(json['addedBy']),
    );
  }
}

class ListDetail {
  const ListDetail({
    required this.id,
    required this.name,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.groupId,
  });

  final String id;
  final String name;
  final String? groupId;
  final String visibility;
  final String createdAt;
  final String updatedAt;
  final List<ListItem> items;

  factory ListDetail.fromJson(Map<String, dynamic> json) {
    return ListDetail(
      id: safeStr(json['id']),
      name: safeStr(json['name']),
      groupId: safeStrOrNull(json['groupId']),
      visibility: safeStr(json['visibility']),
      createdAt: safeStr(json['createdAt']),
      updatedAt: safeStr(json['updatedAt']),
      items: (json['items'] as List<dynamic>)
          .map((i) => ListItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}
