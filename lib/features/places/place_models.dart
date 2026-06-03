import 'package:adondeamos/core/api/json_helpers.dart';

class Place {
  const Place({
    required this.id,
    required this.origin,
    required this.name,
    this.googlePlaceId,
    this.latitude,
    this.longitude,
    this.city,
  });

  final String id;
  final String origin;
  final String? googlePlaceId;
  final String? name;
  final double? latitude;
  final double? longitude;
  final String? city;

  bool get isOwn => origin == 'own';

  bool get isGoogle => origin == 'google';

  String get displayName {
    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty) return cleanName;
    if (isOwn) return 'Lugar propio';
    return 'Lugar de Google';
  }

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: safeStr(json['id']),
      origin: safeStr(json['origin']),
      googlePlaceId: safeStrOrNull(json['googlePlaceId']),
      name: safeStrOrNull(json['name']),
      latitude: safeDoubleOrNull(json['latitude']),
      longitude: safeDoubleOrNull(json['longitude']),
      city: safeStrOrNull(json['city']),
    );
  }
}

class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });

  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: safeStr(json['placeId']),
      description: safeStr(json['description']),
      mainText: safeStrOrNull(json['mainText']),
      secondaryText: safeStrOrNull(json['secondaryText']),
    );
  }
}

class GooglePlaceDetails {
  const GooglePlaceDetails({
    required this.placeId,
    this.displayName,
    this.formattedAddress,
    this.latitude,
    this.longitude,
  });

  final String placeId;
  final String? displayName;
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;

  factory GooglePlaceDetails.fromJson(Map<String, dynamic> json) {
    return GooglePlaceDetails(
      placeId: safeStr(json['placeId']),
      displayName: safeStrOrNull(json['displayName']),
      formattedAddress: safeStrOrNull(json['formattedAddress']),
      latitude: safeDoubleOrNull(json['latitude']),
      longitude: safeDoubleOrNull(json['longitude']),
    );
  }
}

class PlaceResolveResult {
  const PlaceResolveResult({required this.place, required this.google});

  final Place place;
  final GooglePlaceDetails google;

  factory PlaceResolveResult.fromJson(Map<String, dynamic> json) {
    return PlaceResolveResult(
      place: Place.fromJson(json['place'] as Map<String, dynamic>),
      google: GooglePlaceDetails.fromJson(
        json['google'] as Map<String, dynamic>,
      ),
    );
  }
}
