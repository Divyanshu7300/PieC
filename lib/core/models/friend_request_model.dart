import 'dart:convert';
import 'package:piec/core/models/user_model.dart';

enum FriendRequestType {
  knockKnockMap,
  usernameSearch,
  nearbyRadar,
  qrCodeScan,
}

enum FriendPrivacyAccess {
  fullMapAccess, // Home + Office + Live GPS Pin
  chatOnlyNoMap, // E2EE Chat only, map invisible
  blurredCityLevel, // Approximate city location
}

enum RequestStatus {
  pending,
  accepted,
  declined,
}

class FriendRequestModel {
  final String id;
  final UserModel sender;
  final String receiverId;
  final FriendRequestType type;
  final String? placeTitle; // e.g. "Alex's Penthouse 🏠"
  final DateTime timestamp;
  final RequestStatus status;
  final FriendPrivacyAccess privacyAccess;

  const FriendRequestModel({
    required this.id,
    required this.sender,
    required this.receiverId,
    required this.type,
    this.placeTitle,
    required this.timestamp,
    this.status = RequestStatus.pending,
    this.privacyAccess = FriendPrivacyAccess.fullMapAccess,
  });

  String get typeLabel {
    switch (type) {
      case FriendRequestType.knockKnockMap:
        return '🚪 Knock-Knock Map Visit';
      case FriendRequestType.usernameSearch:
        return '🔍 Username Search';
      case FriendRequestType.nearbyRadar:
        return '📡 Nearby Radar Bump';
      case FriendRequestType.qrCodeScan:
        return '📷 3D Snapcode Scan';
    }
  }

  FriendRequestModel copyWith({
    String? id,
    UserModel? sender,
    String? receiverId,
    FriendRequestType? type,
    String? placeTitle,
    DateTime? timestamp,
    RequestStatus? status,
    FriendPrivacyAccess? privacyAccess,
  }) {
    return FriendRequestModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      placeTitle: placeTitle ?? this.placeTitle,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      privacyAccess: privacyAccess ?? this.privacyAccess,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender.toMap(),
      'receiverId': receiverId,
      'type': type.name,
      'placeTitle': placeTitle,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'privacyAccess': privacyAccess.name,
    };
  }

  factory FriendRequestModel.fromMap(Map<String, dynamic> map) {
    return FriendRequestModel(
      id: map['id'] ?? '',
      sender: UserModel.fromMap(map['sender'] ?? {}),
      receiverId: map['receiverId'] ?? '',
      type: FriendRequestType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FriendRequestType.usernameSearch,
      ),
      placeTitle: map['placeTitle'],
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      status: RequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RequestStatus.pending,
      ),
      privacyAccess: FriendPrivacyAccess.values.firstWhere(
        (e) => e.name == map['privacyAccess'],
        orElse: () => FriendPrivacyAccess.fullMapAccess,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory FriendRequestModel.fromJson(String source) =>
      FriendRequestModel.fromMap(json.decode(source));
}
