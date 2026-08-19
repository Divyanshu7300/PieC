import 'package:latlong2/latlong.dart';
import 'package:piec/core/models/avatar_config.dart';

class ConvoyMemberStatus {
  final String userId;
  final String name;
  final String username;
  final AvatarConfig avatarConfig;
  LatLng currentLatLng;
  final LatLng destinationLatLng;
  double speedKmh;
  double distanceKm;
  int etaMinutes;
  bool hasArrived;
  bool isMoving;
  final String vehicleEmoji; // 🚗, 🏍️, 🚙

  ConvoyMemberStatus({
    required this.userId,
    required this.name,
    required this.username,
    required this.avatarConfig,
    required this.currentLatLng,
    required this.destinationLatLng,
    this.speedKmh = 48.0,
    this.distanceKm = 3.5,
    this.etaMinutes = 7,
    this.hasArrived = false,
    this.isMoving = true,
    this.vehicleEmoji = '🚗',
  });
}
