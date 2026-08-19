import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/navigation_route_model.dart';

class NavigationService extends ChangeNotifier {
  final Distance _distance = const Distance();

  NavigationRouteModel? _activeRoute;
  List<LocationPoint> _nearbyPois = [];
  String? _activePoiCategory;

  NavigationRouteModel? get activeRoute => _activeRoute;
  bool get isNavigating => _activeRoute != null;
  List<LocationPoint> get nearbyPois => _nearbyPois;
  String? get activePoiCategory => _activePoiCategory;

  void calculateRoute({
    required LatLng start,
    required LatLng destination,
    required String destTitle,
    required String destAddress,
    TravelMode mode = TravelMode.driving,
  }) {
    final distKm = _distance.as(LengthUnit.Kilometer, start, destination);
    final validDistKm = distKm > 0.1 ? distKm : 2.8;

    int durationMin;
    switch (mode) {
      case TravelMode.twoWheeler:
        durationMin = (validDistKm * 1.8).round().clamp(2, 60);
        break;
      case TravelMode.walking:
        durationMin = (validDistKm * 12.0).round().clamp(5, 180);
        break;
      case TravelMode.driving:
      default:
        durationMin = (validDistKm * 2.2).round().clamp(3, 90);
        break;
    }

    // Generate realistic multi-point turn curve
    final List<LatLng> points = [
      start,
      LatLng(start.latitude + (destination.latitude - start.latitude) * 0.35 + 0.002,
             start.longitude + (destination.longitude - start.longitude) * 0.25),
      LatLng(start.latitude + (destination.latitude - start.latitude) * 0.70 - 0.001,
             start.longitude + (destination.longitude - start.longitude) * 0.65 + 0.002),
      destination,
    ];

    final steps = [
      const NavigationStep(
        instruction: 'Head North onto Central Arterial Blvd',
        distanceText: '400 m',
        iconEmoji: '⬆️',
      ),
      NavigationStep(
        instruction: 'Turn right at Tech Matrix Junction',
        distanceText: '${(validDistKm * 0.4).toStringAsFixed(1)} km',
        iconEmoji: '↗️',
      ),
      NavigationStep(
        instruction: 'Take the flyover towards Expressway Mile 4',
        distanceText: '${(validDistKm * 0.3).toStringAsFixed(1)} km',
        iconEmoji: '🛣️',
      ),
      NavigationStep(
        instruction: 'Destination will be on your left',
        distanceText: '100 m',
        iconEmoji: '🏁',
      ),
    ];

    _activeRoute = NavigationRouteModel(
      destinationTitle: destTitle,
      destinationAddress: destAddress,
      startLatLng: start,
      destinationLatLng: destination,
      routePoints: points,
      distanceKm: validDistKm,
      durationMinutes: durationMin,
      travelMode: mode,
      steps: steps,
    );

    notifyListeners();
  }

  void filterNearbyPois(String category, LatLng center) {
    _activePoiCategory = category;

    switch (category) {
      case '☕ Cafes':
        _nearbyPois = [
          LocationPoint(
            title: 'Blue Tokai Coffee Roasters',
            address: 'Central Square, Block A',
            latitude: center.latitude + 0.004,
            longitude: center.longitude + 0.003,
            type: LocationType.hangout,
            updatedAt: DateTime.now(),
          ),
          LocationPoint(
            title: 'Third Wave Coffee',
            address: 'Metro Walk Boulevard',
            latitude: center.latitude - 0.005,
            longitude: center.longitude + 0.004,
            type: LocationType.hangout,
            updatedAt: DateTime.now(),
          ),
          LocationPoint(
            title: 'Starbucks Cyber City',
            address: 'Tech Plaza Ground Floor',
            latitude: center.latitude + 0.003,
            longitude: center.longitude - 0.006,
            type: LocationType.hangout,
            updatedAt: DateTime.now(),
          ),
        ];
        break;

      case '🍕 Food':
        _nearbyPois = [
          LocationPoint(
            title: 'Artisan Pizza Kitchen',
            address: 'Food Street, Lane 4',
            latitude: center.latitude + 0.006,
            longitude: center.longitude - 0.002,
            type: LocationType.hangout,
            updatedAt: DateTime.now(),
          ),
          LocationPoint(
            title: 'Bao & Dimsum Lounge',
            address: 'Fusion District Level 2',
            latitude: center.latitude - 0.004,
            longitude: center.longitude - 0.005,
            type: LocationType.hangout,
            updatedAt: DateTime.now(),
          ),
        ];
        break;

      case '⛽ Fuel & EV':
        _nearbyPois = [
          LocationPoint(
            title: 'Tata Power EV Supercharger',
            address: 'Expressway Hub 12',
            latitude: center.latitude + 0.008,
            longitude: center.longitude + 0.007,
            type: LocationType.office,
            updatedAt: DateTime.now(),
          ),
          LocationPoint(
            title: 'IndianOil Fuel Station',
            address: 'Main Ring Road Sector 14',
            latitude: center.latitude - 0.007,
            longitude: center.longitude + 0.002,
            type: LocationType.office,
            updatedAt: DateTime.now(),
          ),
        ];
        break;

      case '🏥 Medical':
        _nearbyPois = [
          LocationPoint(
            title: 'Apollo 24/7 Pharmacy',
            address: 'Health City Complex',
            latitude: center.latitude + 0.005,
            longitude: center.longitude - 0.007,
            type: LocationType.office,
            updatedAt: DateTime.now(),
          ),
          LocationPoint(
            title: 'Max Super Specialty Hospital',
            address: 'Sector 5 Medical Boulevard',
            latitude: center.latitude - 0.006,
            longitude: center.longitude - 0.006,
            type: LocationType.office,
            updatedAt: DateTime.now(),
          ),
        ];
        break;

      case '🏧 ATMs':
        _nearbyPois = [
          LocationPoint(
            title: 'HDFC Bank ATM',
            address: 'Central Market Block 2',
            latitude: center.latitude + 0.002,
            longitude: center.longitude + 0.005,
            type: LocationType.office,
            updatedAt: DateTime.now(),
          ),
          LocationPoint(
            title: 'ICICI Bank 24/7 ATM',
            address: 'Metro Station Gate 3',
            latitude: center.latitude - 0.003,
            longitude: center.longitude + 0.003,
            type: LocationType.office,
            updatedAt: DateTime.now(),
          ),
        ];
        break;

      default:
        _nearbyPois = [];
        break;
    }

    notifyListeners();
  }

  void clearPois() {
    _activePoiCategory = null;
    _nearbyPois = [];
    notifyListeners();
  }

  void endNavigation() {
    _activeRoute = null;
    notifyListeners();
  }
}
