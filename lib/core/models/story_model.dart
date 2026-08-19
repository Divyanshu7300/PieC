import 'dart:convert';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/user_model.dart';

enum AvatarSceneType {
  cafeCoffee, // ☕ Sipping brew at cafe
  gamingRig, // 🎮 High-tech VR gaming
  carDrive, // 🚗 Cruising night highway
  pizzaLateNight, // 🍕 Late night snack
  gymWorkout, // 🏋️ Pumping iron
  beachSunset, // 🏖️ Relaxing by the beach
  chillLoFi, // 🎧 Lo-fi headphone vibe
}

class StoryModel {
  final String id;
  final String userId;
  final UserModel user;
  final AvatarSceneType sceneType;
  final String caption;
  final String? musicTrack;
  final LocationPoint? locationPoint; // Geo-Drop location on Map
  final String? squadId; // If squad-only story
  final DateTime createdAt;
  final Duration duration;
  final List<String> viewers;
  final Map<String, String> reactions; // userId -> emoji
  final bool isViewed;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.user,
    this.sceneType = AvatarSceneType.chillLoFi,
    this.caption = '',
    this.musicTrack,
    this.locationPoint,
    this.squadId,
    required this.createdAt,
    this.duration = const Duration(hours: 24),
    this.viewers = const [],
    this.reactions = const {},
    this.isViewed = false,
  });

  String get sceneEmoji {
    switch (sceneType) {
      case AvatarSceneType.cafeCoffee:
        return '☕';
      case AvatarSceneType.gamingRig:
        return '🎮';
      case AvatarSceneType.carDrive:
        return '🚗';
      case AvatarSceneType.pizzaLateNight:
        return '🍕';
      case AvatarSceneType.gymWorkout:
        return '🏋️';
      case AvatarSceneType.beachSunset:
        return '🏖️';
      case AvatarSceneType.chillLoFi:
      default:
        return '🎧';
    }
  }

  String get sceneTitle {
    switch (sceneType) {
      case AvatarSceneType.cafeCoffee:
        return 'Cafe Brew & Chill ☕';
      case AvatarSceneType.gamingRig:
        return 'VR Matrix Grind 🎮';
      case AvatarSceneType.carDrive:
        return 'Night Drive Vibe 🚗';
      case AvatarSceneType.pizzaLateNight:
        return 'Late Night Slice 🍕';
      case AvatarSceneType.gymWorkout:
        return 'Beast Mode Gym 🏋️';
      case AvatarSceneType.beachSunset:
        return 'Golden Hour Sunset 🏖️';
      case AvatarSceneType.chillLoFi:
      default:
        return 'Lo-Fi Chill & Focus 🎧';
    }
  }

  StoryModel copyWith({
    String? id,
    String? userId,
    UserModel? user,
    AvatarSceneType? sceneType,
    String? caption,
    String? musicTrack,
    LocationPoint? locationPoint,
    String? squadId,
    DateTime? createdAt,
    Duration? duration,
    List<String>? viewers,
    Map<String, String>? reactions,
    bool? isViewed,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      sceneType: sceneType ?? this.sceneType,
      caption: caption ?? this.caption,
      musicTrack: musicTrack ?? this.musicTrack,
      locationPoint: locationPoint ?? this.locationPoint,
      squadId: squadId ?? this.squadId,
      createdAt: createdAt ?? this.createdAt,
      duration: duration ?? this.duration,
      viewers: viewers ?? this.viewers,
      reactions: reactions ?? this.reactions,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'user': user.toMap(),
      'sceneType': sceneType.name,
      'caption': caption,
      'musicTrack': musicTrack,
      'locationPoint': locationPoint?.toMap(),
      'squadId': squadId,
      'createdAt': createdAt.toIso8601String(),
      'durationMinutes': duration.inMinutes,
      'viewers': viewers,
      'reactions': reactions,
      'isViewed': isViewed,
    };
  }

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    return StoryModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      user: UserModel.fromMap(map['user'] ?? {}),
      sceneType: AvatarSceneType.values.firstWhere(
        (e) => e.name == map['sceneType'],
        orElse: () => AvatarSceneType.chillLoFi,
      ),
      caption: map['caption'] ?? '',
      musicTrack: map['musicTrack'],
      locationPoint: map['locationPoint'] != null
          ? LocationPoint.fromMap(map['locationPoint'])
          : null,
      squadId: map['squadId'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      duration: Duration(minutes: map['durationMinutes'] ?? 1440),
      viewers: List<String>.from(map['viewers'] ?? []),
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
      isViewed: map['isViewed'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory StoryModel.fromJson(String source) =>
      StoryModel.fromMap(json.decode(source));
}
