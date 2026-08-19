import 'dart:convert';
import 'package:piec/core/models/location_point.dart';

enum MessageType {
  text,
  image,
  video,
  document,
  location,
  audio,
  avatarWave,
}

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String encryptedPayload; // Encrypted Ciphertext
  final String iv; // Initialization vector (Base64)
  final String decryptedContent; // Decrypted on-device content
  final DateTime timestamp;
  final bool isMine;
  final bool isRead;
  final MessageType type;
  final String? reactionEmoji;
  final String? avatarReaction; // 'happy', 'fire', 'shock', 'love', 'dance'
  final String? mediaUrl;
  final String? fileName;
  final String? fileSize;
  final LocationPoint? locationData;
  final String? audioDuration;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.encryptedPayload,
    required this.iv,
    required this.decryptedContent,
    required this.timestamp,
    required this.isMine,
    this.isRead = false,
    this.type = MessageType.text,
    this.reactionEmoji,
    this.avatarReaction,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.locationData,
    this.audioDuration,
  });

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? encryptedPayload,
    String? iv,
    String? decryptedContent,
    DateTime? timestamp,
    bool? isMine,
    bool? isRead,
    MessageType? type,
    String? reactionEmoji,
    String? avatarReaction,
    String? mediaUrl,
    String? fileName,
    String? fileSize,
    LocationPoint? locationData,
    String? audioDuration,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      iv: iv ?? this.iv,
      decryptedContent: decryptedContent ?? this.decryptedContent,
      timestamp: timestamp ?? this.timestamp,
      isMine: isMine ?? this.isMine,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      reactionEmoji: reactionEmoji ?? this.reactionEmoji,
      avatarReaction: avatarReaction ?? this.avatarReaction,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      locationData: locationData ?? this.locationData,
      audioDuration: audioDuration ?? this.audioDuration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'encryptedPayload': encryptedPayload,
      'iv': iv,
      'decryptedContent': decryptedContent,
      'timestamp': timestamp.toIso8601String(),
      'isMine': isMine,
      'isRead': isRead,
      'type': type.name,
      'reactionEmoji': reactionEmoji,
      'avatarReaction': avatarReaction,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'locationData': locationData?.toMap(),
      'audioDuration': audioDuration,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, {String? currentUserId}) {
    final senderId = map['senderId'] ?? '';
    final isMine = currentUserId != null
        ? (senderId == currentUserId)
        : (map['isMine'] ?? false);

    return MessageModel(
      id: map['id'] ?? '',
      senderId: senderId,
      receiverId: map['receiverId'] ?? '',
      encryptedPayload: map['encryptedPayload'] ?? '',
      iv: map['iv'] ?? '',
      decryptedContent: map['decryptedContent'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      isMine: isMine,
      isRead: map['isRead'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      reactionEmoji: map['reactionEmoji'],
      avatarReaction: map['avatarReaction'],
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      locationData: map['locationData'] != null
          ? LocationPoint.fromMap(map['locationData'])
          : null,
      audioDuration: map['audioDuration'],
    );
  }

  String toJson() => json.encode(toMap());

  factory MessageModel.fromJson(String source) =>
      MessageModel.fromMap(json.decode(source));
}
