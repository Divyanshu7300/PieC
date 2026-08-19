import 'dart:convert';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/user_model.dart';

class SquadModel {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String adminId;
  final List<UserModel> members;
  final LocationPoint? meetupLocation; // Shared destination / hangout pin
  final bool isTemporary;
  final DateTime? expiresAt;
  final int colorHex;
  final DateTime createdAt;

  const SquadModel({
    required this.id,
    required this.name,
    required this.emoji,
    this.description = '',
    required this.adminId,
    required this.members,
    this.meetupLocation,
    this.isTemporary = false,
    this.expiresAt,
    this.colorHex = 0xFF00F0FF,
    required this.createdAt,
  });

  SquadModel copyWith({
    String? id,
    String? name,
    String? emoji,
    String? description,
    String? adminId,
    List<UserModel>? members,
    LocationPoint? meetupLocation,
    bool? isTemporary,
    DateTime? expiresAt,
    int? colorHex,
    DateTime? createdAt,
  }) {
    return SquadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      adminId: adminId ?? this.adminId,
      members: members ?? this.members,
      meetupLocation: meetupLocation ?? this.meetupLocation,
      isTemporary: isTemporary ?? this.isTemporary,
      expiresAt: expiresAt ?? this.expiresAt,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'description': description,
      'adminId': adminId,
      'members': members.map((m) => m.toMap()).toList(),
      'meetupLocation': meetupLocation?.toMap(),
      'isTemporary': isTemporary,
      'expiresAt': expiresAt?.toIso8601String(),
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SquadModel.fromMap(Map<String, dynamic> map) {
    return SquadModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '👥',
      description: map['description'] ?? '',
      adminId: map['adminId'] ?? '',
      members: (map['members'] as List? ?? [])
          .map((item) => UserModel.fromMap(item))
          .toList(),
      meetupLocation: map['meetupLocation'] != null
          ? LocationPoint.fromMap(map['meetupLocation'])
          : null,
      isTemporary: map['isTemporary'] ?? false,
      expiresAt: DateTime.tryParse(map['expiresAt'] ?? ''),
      colorHex: map['colorHex'] ?? 0xFF00F0FF,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SquadModel.fromJson(String source) =>
      SquadModel.fromMap(json.decode(source));
}
