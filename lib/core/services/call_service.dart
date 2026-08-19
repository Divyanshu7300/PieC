import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:piec/core/models/call_session_model.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:uuid/uuid.dart';

class CallService extends ChangeNotifier {
  final Uuid _uuid = const Uuid();

  CallSessionModel? _activeCall;
  Timer? _durationTimer;
  Timer? _connectSimulationTimer;

  CallSessionModel? get activeCall => _activeCall;
  bool get isInCall => _activeCall != null && _activeCall!.status != CallStatus.ended;

  void startCall({
    required UserModel caller,
    required UserModel receiver,
    required CallType type,
  }) {
    _durationTimer?.cancel();
    _connectSimulationTimer?.cancel();

    _activeCall = CallSessionModel(
      callId: 'call_${_uuid.v4().substring(0, 8)}',
      caller: caller,
      receiver: receiver,
      type: type,
      status: CallStatus.ringing,
      startTime: DateTime.now(),
      isVideoOn: type == CallType.avatarVideo,
    );
    notifyListeners();

    // Auto connect simulation after 1.4 seconds
    _connectSimulationTimer = Timer(const Duration(milliseconds: 1400), () {
      if (_activeCall != null && _activeCall!.status == CallStatus.ringing) {
        _activeCall = _activeCall!.copyWith(status: CallStatus.connected);
        _startDurationTimer();
        notifyListeners();
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeCall != null && _activeCall!.status == CallStatus.connected) {
        _activeCall = _activeCall!.copyWith(
          durationSeconds: _activeCall!.durationSeconds + 1,
        );
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void toggleMute() {
    if (_activeCall != null) {
      _activeCall = _activeCall!.copyWith(isMuted: !_activeCall!.isMuted);
      notifyListeners();
    }
  }

  void toggleVideo() {
    if (_activeCall != null) {
      _activeCall = _activeCall!.copyWith(isVideoOn: !_activeCall!.isVideoOn);
      notifyListeners();
    }
  }

  void toggleSpeaker() {
    if (_activeCall != null) {
      _activeCall = _activeCall!.copyWith(isSpeakerOn: !_activeCall!.isSpeakerOn);
      notifyListeners();
    }
  }

  void setLensFilter(String? filterName) {
    if (_activeCall != null) {
      _activeCall = _activeCall!.copyWith(activeLensFilter: filterName);
      notifyListeners();
    }
  }

  void endCall() {
    _durationTimer?.cancel();
    _connectSimulationTimer?.cancel();
    if (_activeCall != null) {
      _activeCall = _activeCall!.copyWith(status: CallStatus.ended);
      notifyListeners();
    }
    Timer(const Duration(milliseconds: 400), () {
      _activeCall = null;
      notifyListeners();
    });
  }
}
