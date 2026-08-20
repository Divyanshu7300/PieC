import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:piec/core/models/call_session_model.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:uuid/uuid.dart';

class CallService extends ChangeNotifier {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CallSessionModel? _activeCall;
  CallSessionModel? _incomingCall;
  Timer? _durationTimer;
  StreamSubscription<DocumentSnapshot>? _activeCallSub;
  StreamSubscription<QuerySnapshot>? _incomingCallSub;
  String? _currentUserId;

  CallSessionModel? get activeCall => _activeCall;
  CallSessionModel? get incomingCall => _incomingCall;
  bool get isInCall => _activeCall != null && _activeCall!.status != CallStatus.ended;

  Future<void> init(String currentUserId) async {
    _currentUserId = currentUserId;
    _incomingCallSub?.cancel();

    // Listen to real-time incoming calls from Cloud Firestore
    try {
      _incomingCallSub = _db
          .collection('calls')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'ringing')
          .snapshots()
          .listen((snap) {
        if (snap.docs.isNotEmpty) {
          final doc = snap.docs.first;
          final data = doc.data();
          _incomingCall = CallSessionModel(
            callId: doc.id,
            caller: UserModel(
              id: data['callerId'] ?? '',
              name: data['callerName'] ?? 'PieC Friend',
              username: data['callerUsername'] ?? 'friend',
              lastActive: DateTime.now(),
            ),
            receiver: UserModel(
              id: currentUserId,
              name: 'Me',
              username: 'me',
              lastActive: DateTime.now(),
            ),
            type: data['type'] == 'avatarVideo' ? CallType.avatarVideo : CallType.audio,
            status: CallStatus.ringing,
            startTime: DateTime.now(),
          );
        } else {
          _incomingCall = null;
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Incoming call listener error: $e');
    }
  }

  Future<void> startCall({
    required UserModel caller,
    required UserModel receiver,
    required CallType type,
  }) async {
    _durationTimer?.cancel();
    _activeCallSub?.cancel();

    final callId = 'call_${_uuid.v4().substring(0, 8)}';
    _activeCall = CallSessionModel(
      callId: callId,
      caller: caller,
      receiver: receiver,
      type: type,
      status: CallStatus.ringing,
      startTime: DateTime.now(),
      isVideoOn: type == CallType.avatarVideo,
    );
    notifyListeners();

    // 1. Write call session to Firestore
    try {
      await _db.collection('calls').doc(callId).set({
        'callId': callId,
        'callerId': caller.id,
        'callerName': caller.name,
        'callerUsername': caller.username,
        'receiverId': receiver.id,
        'receiverName': receiver.name,
        'type': type == CallType.avatarVideo ? 'avatarVideo' : 'audio',
        'status': 'ringing',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Listen for receiver acceptance or decline in real time
      _activeCallSub = _db.collection('calls').doc(callId).snapshots().listen((snap) {
        if (!snap.exists) return;
        final data = snap.data();
        if (data != null) {
          final statusStr = data['status'] as String?;
          if (statusStr == 'connected' && _activeCall?.status == CallStatus.ringing) {
            _activeCall = _activeCall!.copyWith(status: CallStatus.connected);
            _startDurationTimer();
            notifyListeners();
          } else if (statusStr == 'declined' || statusStr == 'ended') {
            endCall();
          }
        }
      });
    } catch (e) {
      debugPrint('Error starting call on Firestore: $e');
    }
  }

  Future<void> acceptIncomingCall() async {
    if (_incomingCall == null) return;
    final call = _incomingCall!;
    _incomingCall = null;
    _activeCall = call.copyWith(status: CallStatus.connected);
    _startDurationTimer();
    notifyListeners();

    try {
      await _db.collection('calls').doc(call.callId).update({
        'status': 'connected',
        'connectedAt': FieldValue.serverTimestamp(),
      });

      // Listen for remote hangup
      _activeCallSub?.cancel();
      _activeCallSub = _db.collection('calls').doc(call.callId).snapshots().listen((snap) {
        if (!snap.exists) return;
        final data = snap.data();
        if (data != null && (data['status'] == 'ended' || data['status'] == 'declined')) {
          endCall();
        }
      });
    } catch (e) {
      debugPrint('Error accepting call on Firestore: $e');
    }
  }

  Future<void> declineIncomingCall() async {
    if (_incomingCall == null) return;
    final callId = _incomingCall!.callId;
    _incomingCall = null;
    notifyListeners();

    try {
      await _db.collection('calls').doc(callId).update({
        'status': 'declined',
      });
    } catch (e) {
      debugPrint('Error declining call on Firestore: $e');
    }
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

  Future<void> endCall() async {
    _durationTimer?.cancel();
    _activeCallSub?.cancel();

    if (_activeCall != null) {
      final callId = _activeCall!.callId;
      _activeCall = _activeCall!.copyWith(status: CallStatus.ended);
      notifyListeners();

      try {
        await _db.collection('calls').doc(callId).update({
          'status': 'ended',
        });
      } catch (_) {}
    }

    Timer(const Duration(milliseconds: 400), () {
      _activeCall = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _activeCallSub?.cancel();
    _incomingCallSub?.cancel();
    super.dispose();
  }
}
