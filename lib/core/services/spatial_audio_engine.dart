import 'dart:async';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class SpatialAudioEngine {
  static final SpatialAudioEngine _instance = SpatialAudioEngine._internal();
  factory SpatialAudioEngine() => _instance;
  SpatialAudioEngine._internal();

  Timer? _ringtoneTimer;
  Timer? _voiceStreamTimer;
  bool _isPlayingRingtone = false;
  bool _isVoiceActive = false;

  bool get isPlayingRingtone => _isPlayingRingtone;
  bool get isVoiceActive => _isVoiceActive;

  void _playTone(double frequency, double durationSeconds, {String type = 'sine', double volume = 0.2}) {
    if (kIsWeb) {
      try {
        js.context.callMethod('playSpatialTone', [frequency, durationSeconds, type, volume]);
      } catch (e) {
        debugPrint('WebAudio error: $e');
      }
    } else {
      debugPrint('🎵 [SpatialAudioEngine] Audio Tone: ${frequency}Hz for ${durationSeconds}s');
    }
  }

  // 1. Play Outgoing / Incoming Ringtone (Audible 440Hz / 480Hz ring tone)
  void startRingtone() {
    stopRingtone();
    _isPlayingRingtone = true;
    _playTone(440.0, 1.2, type: 'sine', volume: 0.25);

    _ringtoneTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isPlayingRingtone) {
        timer.cancel();
        return;
      }
      _playTone(440.0, 1.2, type: 'sine', volume: 0.25);
    });
  }

  void stopRingtone() {
    _isPlayingRingtone = false;
    _ringtoneTimer?.cancel();
    _ringtoneTimer = null;
  }

  // 2. Start In-Call Spatial HD Voice Stream
  void startCallVoiceStream() {
    stopRingtone();
    _isVoiceActive = true;
    playCallConnectedChime();

    _voiceStreamTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isVoiceActive) {
        timer.cancel();
        return;
      }
      _playTone(320.0, 0.12, type: 'triangle', volume: 0.08);
    });
  }

  void stopCallVoiceStream() {
    _isVoiceActive = false;
    _voiceStreamTimer?.cancel();
    _voiceStreamTimer = null;
  }

  // 3. Play Call Connected Chime
  void playCallConnectedChime() {
    stopRingtone();
    _playTone(523.25, 0.15, type: 'sine', volume: 0.3); // C5
    Future.delayed(const Duration(milliseconds: 160), () {
      _playTone(659.25, 0.25, type: 'sine', volume: 0.3); // E5
    });
  }

  // 4. Play Call Hangup Chime
  void playCallHangupChime() {
    stopRingtone();
    stopCallVoiceStream();
    _playTone(440.0, 0.15, type: 'sine', volume: 0.25);
    Future.delayed(const Duration(milliseconds: 160), () {
      _playTone(349.23, 0.3, type: 'sine', volume: 0.25);
    });
  }

  // 5. Play Notification Message Ping Chime
  void playNotificationChime() {
    _playTone(880.0, 0.1, type: 'sine', volume: 0.3);
    Future.delayed(const Duration(milliseconds: 120), () {
      _playTone(1318.51, 0.2, type: 'sine', volume: 0.3);
    });
  }
}
