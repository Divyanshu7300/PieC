import 'package:latlong2/latlong.dart';

enum LocationType { home, office, hangout, live }

class LocationPoint {
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final LocationType type;
  final DateTime updatedAt;

  const LocationPoint({
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.updatedAt,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  String get iconEmoji {
    switch (type) {
      case LocationType.home:
        return '🏠';
      case LocationType.office:
        return '💼';
      case LocationType.hangout:
        return '☕';
      case LocationType.live:
        return '📍';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      title: map['title'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      type: LocationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => LocationType.live,
      ),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
