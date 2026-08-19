import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:piec/core/models/location_point.dart';

class SearchResultLocation {
  final String displayName;
  final double latitude;
  final double longitude;

  const SearchResultLocation({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const LatLng defaultLatLng = LatLng(28.6139, 77.2090);

  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }
  }

  /// Searches real worldwide addresses using OpenStreetMap Nominatim Geocoding API
  Future<List<SearchResultLocation>> searchWorldwideAddresses(String query) async {
    if (query.trim().length < 2) return [];

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'PieC_Spatial_App/1.0 (social@piec.app)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) {
          return SearchResultLocation(
            displayName: item['display_name'] ?? 'Unknown location',
            latitude: double.tryParse(item['lat'].toString()) ?? 0.0,
            longitude: double.tryParse(item['lon'].toString()) ?? 0.0,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Address search error: $e');
    }
    return [];
  }

  String formatDistance(LatLng from, LatLng to) {
    const Distance distance = Distance();
    final double meter = distance.as(LengthUnit.Meter, from, to);
    if (meter < 1000) {
      return '${meter.round()} m away';
    } else {
      final km = meter / 1000;
      return '${km.toStringAsFixed(1)} km away';
    }
  }

  LocationPoint createPoint({
    required String title,
    required String address,
    required double latitude,
    required double longitude,
    required LocationType type,
  }) {
    return LocationPoint(
      title: title,
      address: address,
      latitude: latitude,
      longitude: longitude,
      type: type,
      updatedAt: DateTime.now(),
    );
  }
}
