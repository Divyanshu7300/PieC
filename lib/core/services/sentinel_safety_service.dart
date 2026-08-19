import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/user_model.dart';

class SentinelSafetyService extends ChangeNotifier {
  final Distance _distance = const Distance();

  bool _isRideSentinelActive = false;
  bool _isSosPanicActive = false;
  LocationPoint? _targetHomePoint;
  int _distanceToHomeMeters = 1800;
  String? _safeArrivalAlert;
  String? _sosBroadcastMessage;
  Timer? _rideSimTimer;

  bool get isRideSentinelActive => _isRideSentinelActive;
  bool get isSosPanicActive => _isSosPanicActive;
  LocationPoint? get targetHomePoint => _targetHomePoint;
  int get distanceToHomeMeters => _distanceToHomeMeters;
  String? get safeArrivalAlert => _safeArrivalAlert;
  String? get sosBroadcastMessage => _sosBroadcastMessage;

  void startSafeRideHome(LocationPoint homePoint, UserModel? currentUser) {
    _isRideSentinelActive = true;
    _targetHomePoint = homePoint;
    _distanceToHomeMeters = 1800;
    _safeArrivalAlert = null;
    notifyListeners();

    _startGeofenceMonitor(currentUser);
  }

  void _startGeofenceMonitor(UserModel? currentUser) {
    _rideSimTimer?.cancel();
    _rideSimTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isRideSentinelActive) {
        timer.cancel();
        return;
      }

      if (_distanceToHomeMeters > 50) {
        _distanceToHomeMeters -= 300;
        if (_distanceToHomeMeters < 50) _distanceToHomeMeters = 20;
        notifyListeners();
      } else {
        // Geofence Triggered (Entered 50m radius of Home Base!)
        _isRideSentinelActive = false;
        _safeArrivalAlert = '✅ ${currentUser?.name.split(' ').first ?? 'You'} reached Home Base safely! Parents & Squad notified automatically.';
        notifyListeners();
        timer.cancel();
      }
    });
  }

  void triggerSosEmergency(UserModel? currentUser) {
    _isSosPanicActive = true;
    _sosBroadcastMessage = '🚨 EMERGENCY SOS: ${currentUser?.name ?? 'User'} triggered safety beacon at ${currentUser?.liveLocation?.address ?? 'Live Location'}! Coordinates shared to Police & Squad.';
    notifyListeners();
  }

  void dismissSafeArrivalAlert() {
    _safeArrivalAlert = null;
    notifyListeners();
  }

  void cancelSos() {
    _isSosPanicActive = false;
    _sosBroadcastMessage = null;
    notifyListeners();
  }

  void cancelRideSentinel() {
    _isRideSentinelActive = false;
    _rideSimTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _rideSimTimer?.cancel();
    super.dispose();
  }
}
