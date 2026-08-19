import 'package:piec/core/models/user_model.dart';

enum CallType {
  audio,
  avatarVideo,
  groupSquad,
}

enum CallStatus {
  ringing,
  connected,
  ended,
}

class CallSessionModel {
  final String callId;
  final UserModel caller;
  final UserModel receiver;
  final CallType type;
  final CallStatus status;
  final DateTime startTime;
  final int durationSeconds;
  final bool isMuted;
  final bool isVideoOn;
  final bool isSpeakerOn;
  final String? activeLensFilter; // e.g. "Holo Visor", "Neon Crown"

  const CallSessionModel({
    required this.callId,
    required this.caller,
    required this.receiver,
    required this.type,
    this.status = CallStatus.ringing,
    required this.startTime,
    this.durationSeconds = 0,
    this.isMuted = false,
    this.isVideoOn = true,
    this.isSpeakerOn = true,
    this.activeLensFilter,
  });

  CallSessionModel copyWith({
    String? callId,
    UserModel? caller,
    UserModel? receiver,
    CallType? type,
    CallStatus? status,
    DateTime? startTime,
    int? durationSeconds,
    bool? isMuted,
    bool? isVideoOn,
    bool? isSpeakerOn,
    String? activeLensFilter,
  }) {
    return CallSessionModel(
      callId: callId ?? this.callId,
      caller: caller ?? this.caller,
      receiver: receiver ?? this.receiver,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isMuted: isMuted ?? this.isMuted,
      isVideoOn: isVideoOn ?? this.isVideoOn,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      activeLensFilter: activeLensFilter ?? this.activeLensFilter,
    );
  }
}
