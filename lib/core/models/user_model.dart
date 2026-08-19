import 'dart:convert';
import 'package:piec/core/models/avatar_config.dart';
import 'package:piec/core/models/location_point.dart';

enum LocationPrivacyMode {
  precise, // 🎯 Exact GPS street location
  blurred, // 🏙️ Blurred city / neighborhood area only
  ghost, // 👻 Completely invisible
}

class UserModel {
  final String id;
  final String name;
  final String username;
  final String? phone;
  final String? email;
  final AvatarConfig avatarConfig;
  final LocationPoint? liveLocation;
  final LocationPoint? homeLocation;
  final LocationPoint? officeLocation;
  final String statusText;
  final bool isOnline;
  final bool isGhostMode;
  final LocationPrivacyMode privacyMode;
  final int batteryPercentage;
  final bool isCharging;
  final DateTime? lastKnownBeaconTime;
  final String? lastKnownBeaconAddress;
  final String publicKey;
  final DateTime lastActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    this.phone,
    this.email,
    this.avatarConfig = const AvatarConfig(),
    this.liveLocation,
    this.homeLocation,
    this.officeLocation,
    this.statusText = 'Chilling 🎮',
    this.isOnline = true,
    this.isGhostMode = false,
    this.privacyMode = LocationPrivacyMode.precise,
    this.batteryPercentage = 84,
    this.isCharging = false,
    this.lastKnownBeaconTime,
    this.lastKnownBeaconAddress,
    this.publicKey = '',
    required this.lastActive,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? phone,
    String? email,
    AvatarConfig? avatarConfig,
    LocationPoint? liveLocation,
    LocationPoint? homeLocation,
    LocationPoint? officeLocation,
    String? statusText,
    bool? isOnline,
    bool? isGhostMode,
    LocationPrivacyMode? privacyMode,
    int? batteryPercentage,
    bool? isCharging,
    DateTime? lastKnownBeaconTime,
    String? lastKnownBeaconAddress,
    String? publicKey,
    DateTime? lastActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarConfig: avatarConfig ?? this.avatarConfig,
      liveLocation: liveLocation ?? this.liveLocation,
      homeLocation: homeLocation ?? this.homeLocation,
      officeLocation: officeLocation ?? this.officeLocation,
      statusText: statusText ?? this.statusText,
      isOnline: isOnline ?? this.isOnline,
      isGhostMode: isGhostMode ?? this.isGhostMode,
      privacyMode: privacyMode ?? this.privacyMode,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      isCharging: isCharging ?? this.isCharging,
      lastKnownBeaconTime: lastKnownBeaconTime ?? this.lastKnownBeaconTime,
      lastKnownBeaconAddress: lastKnownBeaconAddress ?? this.lastKnownBeaconAddress,
      publicKey: publicKey ?? this.publicKey,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'phone': phone,
      'email': email,
      'avatarConfig': avatarConfig.toMap(),
      'liveLocation': liveLocation?.toMap(),
      'homeLocation': homeLocation?.toMap(),
      'officeLocation': officeLocation?.toMap(),
      'statusText': statusText,
      'isOnline': isOnline,
      'isGhostMode': isGhostMode,
      'privacyMode': privacyMode.name,
      'batteryPercentage': batteryPercentage,
      'isCharging': isCharging,
      'lastKnownBeaconTime': lastKnownBeaconTime?.toIso8601String(),
      'lastKnownBeaconAddress': lastKnownBeaconAddress,
      'publicKey': publicKey,
      'lastActive': lastActive.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      phone: map['phone'],
      email: map['email'],
      avatarConfig: map['avatarConfig'] != null
          ? AvatarConfig.fromMap(map['avatarConfig'])
          : const AvatarConfig(),
      liveLocation: map['liveLocation'] != null
          ? LocationPoint.fromMap(map['liveLocation'])
          : null,
      homeLocation: map['homeLocation'] != null
          ? LocationPoint.fromMap(map['homeLocation'])
          : null,
      officeLocation: map['officeLocation'] != null
          ? LocationPoint.fromMap(map['officeLocation'])
          : null,
      statusText: map['statusText'] ?? 'Chilling 🎮',
      isOnline: map['isOnline'] ?? true,
      isGhostMode: map['isGhostMode'] ?? false,
      privacyMode: LocationPrivacyMode.values.firstWhere(
        (e) => e.name == map['privacyMode'],
        orElse: () => LocationPrivacyMode.precise,
      ),
      batteryPercentage: map['batteryPercentage'] ?? 84,
      isCharging: map['isCharging'] ?? false,
      lastKnownBeaconTime: map['lastKnownBeaconTime'] != null
          ? DateTime.tryParse(map['lastKnownBeaconTime'])
          : null,
      lastKnownBeaconAddress: map['lastKnownBeaconAddress'],
      publicKey: map['publicKey'] ?? '',
      lastActive: DateTime.tryParse(map['lastActive'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));
}
