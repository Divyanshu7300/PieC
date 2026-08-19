import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:piec/core/models/avatar_config.dart';
import 'package:piec/core/models/convoy_member_status.dart';
import 'package:piec/core/models/squad_model.dart';
import 'package:piec/core/models/user_model.dart';

class ConvoyService extends ChangeNotifier {
  final Distance _distance = const Distance();

  List<ConvoyMemberStatus> _members = [];
  bool _isConvoyActive = false;
  bool _isSimulatingMovement = true;
  Timer? _simulationTimer;
  String? _lastHonkMessage;
  Timer? _honkTimer;

  List<ConvoyMemberStatus> get members => _members;
  bool get isConvoyActive => _isConvoyActive;
  bool get isSimulatingMovement => _isSimulatingMovement;
  String? get lastHonkMessage => _lastHonkMessage;

  void initForSquad(SquadModel? squad, UserModel? currentUser) {
    _simulationTimer?.cancel();
    if (squad == null || squad.meetupLocation == null) {
      _isConvoyActive = false;
      _members = [];
      notifyListeners();
      return;
    }

    _isConvoyActive = true;
    final dest = squad.meetupLocation!.latLng;

    _members = [];

    // 1. Current User Convoy entry
    if (currentUser != null) {
      final startPos = currentUser.liveLocation?.latLng ?? LatLng(dest.latitude - 0.015, dest.longitude - 0.012);
      final distKm = _distance.as(LengthUnit.Kilometer, startPos, dest);
      _members.add(
        ConvoyMemberStatus(
          userId: currentUser.id,
          name: currentUser.name,
          username: currentUser.username,
          avatarConfig: currentUser.avatarConfig,
          currentLatLng: startPos,
          destinationLatLng: dest,
          speedKmh: 54.0,
          distanceKm: distKm > 0 ? distKm : 2.4,
          etaMinutes: ((distKm > 0 ? distKm : 2.4) * 2.2).round().clamp(1, 30),
          vehicleEmoji: '🚗',
        ),
      );
    }

    // 2. Squad Members
    final vehicles = ['🏍️', '🚙', '🏎️', '🚗'];
    int idx = 0;
    for (final member in squad.members) {
      if (currentUser != null && member.id == currentUser.id) continue;

      final offsetLat = (idx % 2 == 0 ? 0.012 : -0.014) * (idx + 1) * 0.7;
      final offsetLng = (idx % 2 == 0 ? -0.015 : 0.011) * (idx + 1) * 0.7;
      final startPos = LatLng(dest.latitude + offsetLat, dest.longitude + offsetLng);
      final distKm = _distance.as(LengthUnit.Kilometer, startPos, dest);

      _members.add(
        ConvoyMemberStatus(
          userId: member.id,
          name: member.name,
          username: member.username,
          avatarConfig: member.avatarConfig,
          currentLatLng: startPos,
          destinationLatLng: dest,
          speedKmh: 45.0 + (idx * 6),
          distanceKm: distKm > 0 ? distKm : (1.8 + idx * 0.9),
          etaMinutes: ((distKm > 0 ? distKm : (1.8 + idx * 0.9)) * 2.0).round().clamp(1, 25),
          vehicleEmoji: vehicles[idx % vehicles.length],
        ),
      );
      idx++;
    }

    _startMovementLoop();
    notifyListeners();
  }

  void _startMovementLoop() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!_isSimulatingMovement) return;

      bool anyUpdated = false;
      for (final m in _members) {
        if (m.hasArrived) continue;

        // Step movement towards destination
        final dLat = m.destinationLatLng.latitude - m.currentLatLng.latitude;
        final dLng = m.destinationLatLng.longitude - m.currentLatLng.longitude;
        final dist = math.sqrt(dLat * dLat + dLng * dLng);

        if (dist < 0.0008) {
          m.hasArrived = true;
          m.speedKmh = 0;
          m.distanceKm = 0;
          m.etaMinutes = 0;
          m.currentLatLng = m.destinationLatLng;
        } else {
          // Move 4% of remaining distance per tick with small realistic speed variance
          const stepRatio = 0.035;
          m.currentLatLng = LatLng(
            m.currentLatLng.latitude + (dLat * stepRatio),
            m.currentLatLng.longitude + (dLng * stepRatio),
          );
          final realDistKm = _distance.as(LengthUnit.Kilometer, m.currentLatLng, m.destinationLatLng);
          m.distanceKm = realDistKm;
          m.etaMinutes = (realDistKm * 2.1).round().clamp(1, 30);
          m.speedKmh = (48 + (math.Random().nextInt(12) - 6)).toDouble();
        }
        anyUpdated = true;
      }

      if (anyUpdated) {
        notifyListeners();
      }
    });
  }

  void toggleMovementSimulation() {
    _isSimulatingMovement = !_isSimulatingMovement;
    notifyListeners();
  }

  void honkHorn(String senderName) {
    _lastHonkMessage = '$senderName honked at the convoy! 📢🚗';
    notifyListeners();

    _honkTimer?.cancel();
    _honkTimer = Timer(const Duration(seconds: 3), () {
      _lastHonkMessage = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _honkTimer?.cancel();
    super.dispose();
  }
}
