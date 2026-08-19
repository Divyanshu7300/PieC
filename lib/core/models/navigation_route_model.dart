import 'package:latlong2/latlong.dart';

enum TravelMode {
  driving, // 🚗 Car
  twoWheeler, // 🏍️ Bike / Scooter
  walking, // 🚶 Walking
}

class NavigationStep {
  final String instruction;
  final String distanceText;
  final String iconEmoji;

  const NavigationStep({
    required this.instruction,
    required this.distanceText,
    required this.iconEmoji,
  });
}

class NavigationRouteModel {
  final String destinationTitle;
  final String destinationAddress;
  final LatLng startLatLng;
  final LatLng destinationLatLng;
  final List<LatLng> routePoints;
  final double distanceKm;
  final int durationMinutes;
  final TravelMode travelMode;
  final List<NavigationStep> steps;

  const NavigationRouteModel({
    required this.destinationTitle,
    required this.destinationAddress,
    required this.startLatLng,
    required this.destinationLatLng,
    required this.routePoints,
    required this.distanceKm,
    required this.durationMinutes,
    this.travelMode = TravelMode.driving,
    required this.steps,
  });
}
