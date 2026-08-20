import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/user_model.dart';

class LocationService extends ChangeNotifier {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;
  double _currentSpeedKmH = 0.0;
  double _currentHeading = 0.0;
  String _currentAddress = 'Live Spatial GPS';

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  double get currentSpeedKmH => _currentSpeedKmH;
  double get currentHeading => _currentHeading;
  String get currentAddress => _currentAddress;

  // Default coordinate if GPS is initializing or disabled (Connaught Place, New Delhi)
  double get latitude => _currentPosition?.latitude ?? 28.6139;
  double get longitude => _currentPosition?.longitude ?? 77.2090;

  LocationPoint get currentLocationPoint => LocationPoint(
        title: 'Current Location',
        address: _currentAddress,
        latitude: latitude,
        longitude: longitude,
        type: LocationType.live,
        updatedAt: DateTime.now(),
      );

  // Initialize and start live GPS streaming
  Future<void> startLocationTracking({String? currentUserId}) async {
    if (_isTracking) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }

      // Get initial position quickly
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        _updateSpeedAndHeading(_currentPosition!);
        notifyListeners();
        if (currentUserId != null) {
          _syncLocationToFirestore(currentUserId, _currentPosition!);
        }
      } catch (e) {
        debugPrint('Quick location fix error: ');
      }

      // Stream real-time moving updates
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // update every 3 meters
      );

      _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          _currentPosition = position;
          _updateSpeedAndHeading(position);
          notifyListeners();

          if (currentUserId != null) {
            _syncLocationToFirestore(currentUserId, position);
          }
        },
        onError: (e) {
          debugPrint('Location stream error: ');
        },
      );

      _isTracking = true;
      notifyListeners();
    } catch (e) {
      debugPrint('startLocationTracking error: ');
    }
  }

  void _updateSpeedAndHeading(Position pos) {
    _currentSpeedKmH = (pos.speed > 0) ? (pos.speed * 3.6) : 0.0;
    _currentHeading = pos.heading;
  }

  // Sync GPS to Firestore in real-time
  Future<void> _syncLocationToFirestore(String userId, Position pos) async {
    try {
      await _db.collection('users').doc(userId).set({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'speed': _currentSpeedKmH,
        'heading': pos.heading,
        'altitude': pos.altitude,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing location to Firestore: ');
    }
  }

  // Stream live coordinates of all friends
  Stream<List<UserModel>> streamLiveFriends(List<String> friendIds) {
    if (friendIds.isEmpty) {
      return Stream.value([]);
    }

    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => friendIds.contains(doc.id))
          .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Haversine accurate spherical distance in meters
  double calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusMeters = 6371000;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Format distance for high-tech HUD
  String formatDistance(double meters) {
    if (meters < 10) {
      return 'Right here (<10m)';
    } else if (meters < 1000) {
      return '${meters.toInt()}m away';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km away';
    }
  }

  // ETA Estimation based on walking (5 km/h) or driving
  String estimateTravelTime(double meters, {double? speedKmH}) {
    if (meters < 50) return 'Arrived! 📍';

    final effectiveSpeed = (speedKmH != null && speedKmH > 10) ? speedKmH : 5.0;
    final speedMps = effectiveSpeed * (1000 / 3600);
    final seconds = meters / speedMps;
    final minutes = (seconds / 60).ceil();

    if (minutes < 1) return '< 1 min away';
    if (minutes < 60) return '$minutes min away';
    final hours = (minutes / 60).floor();
    final remMin = minutes % 60;
    return '${hours}h ${remMin}m away';
  }

  // Compass Bearing / Heading string (e.g. "NE", "SW")
  String getBearingDirection(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _degreesToRadians(lon2 - lon1);
    final y = math.sin(dLon) * math.cos(_degreesToRadians(lat2));
    final x = math.cos(_degreesToRadians(lat1)) * math.sin(_degreesToRadians(lat2)) -
        math.sin(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) * math.cos(dLon);

    final radians = math.atan2(y, x);
    final degrees = (radians * 180 / math.pi + 360) % 360;

    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N'];
    final index = ((degrees + 22.5) / 45).floor();
    return directions[index];
  }

  // Quick one-shot position getter
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
    } catch (_) {
      return _currentPosition;
    }
  }

  // Worldwide address and POI search
  Future<List<SearchResultLocation>> searchWorldwideAddresses(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();

    // Built-in worldwide popular locations & landmarks
    final presetLocations = [
      SearchResultLocation(
        title: 'Connaught Place',
        address: 'New Delhi, Delhi, India',
        latitude: 28.6315,
        longitude: 77.2167,
      ),
      SearchResultLocation(
        title: 'India Gate',
        address: 'Rajpath, India Gate, New Delhi, India',
        latitude: 28.6129,
        longitude: 77.2295,
      ),
      SearchResultLocation(
        title: 'Cyber Hub',
        address: 'DLF Cyber City, Gurugram, Haryana, India',
        latitude: 28.4952,
        longitude: 77.0890,
      ),
      SearchResultLocation(
        title: 'Bandra Bandstand',
        address: 'Bandra West, Mumbai, Maharashtra, India',
        latitude: 19.0435,
        longitude: 72.8194,
      ),
      SearchResultLocation(
        title: 'Indiranagar 100ft Rd',
        address: 'Indiranagar, Bengaluru, Karnataka, India',
        latitude: 12.9719,
        longitude: 77.6412,
      ),
      SearchResultLocation(
        title: 'Times Square',
        address: 'Manhattan, NY 10036, United States',
        latitude: 40.7580,
        longitude: -73.9855,
      ),
      SearchResultLocation(
        title: 'Shibuya Crossing',
        address: 'Shibuya City, Tokyo 150-0043, Japan',
        latitude: 35.6595,
        longitude: 139.7004,
      ),
      SearchResultLocation(
        title: 'Eiffel Tower',
        address: 'Champ de Mars, Paris, France',
        latitude: 48.8584,
        longitude: 2.2945,
      ),
    ];

    return presetLocations.where((loc) {
      return loc.title.toLowerCase().contains(q) ||
          loc.address.toLowerCase().contains(q);
    }).toList();
  }

  void stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

class SearchResultLocation {
  final String title;
  final String address;
  final double latitude;
  final double longitude;

  const SearchResultLocation({
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  String get displayName => address.isNotEmpty ? address : title;
  LatLng get latLng => LatLng(latitude, longitude);
}

