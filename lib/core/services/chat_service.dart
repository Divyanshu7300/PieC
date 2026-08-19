import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:piec/core/crypto/e2ee_engine.dart';
import 'package:piec/core/models/avatar_config.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/message_model.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class ChatService extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final E2EEEngine _crypto = E2EEEngine();
  final Uuid _uuid = const Uuid();

  List<UserModel> _friends = [];
  final Map<String, List<MessageModel>> _chatHistory = {};
  final Map<String, bool> _typingUsers = {};
  final Map<String, String> _activeAvatarReactions = {};

  List<UserModel> get friends => _friends;
  Map<String, bool> get typingUsers => _typingUsers;
  Map<String, String> get activeAvatarReactions => _activeAvatarReactions;

  Future<void> init(String currentUserId) async {
    _friends = [];
    final cachedFriends = await _storage.getFriends(currentUserId);
    if (cachedFriends.isNotEmpty) {
      _friends = cachedFriends;
      for (final friend in _friends) {
        final cached = await _storage.getMessages(friend.id, currentUserId);
        if (cached.isNotEmpty) {
          final decryptedList = cached.map((msg) {
            final decrypted = _crypto.decryptMessage(
              cipherText: msg.encryptedPayload,
              ivBase64: msg.iv,
              senderId: msg.senderId,
              receiverId: msg.receiverId,
            );
            return msg.copyWith(decryptedContent: decrypted);
          }).toList();
          _chatHistory[friend.id] = decryptedList;
        }
      }
    }
    notifyListeners();
  }

  void addFriend(UserModel friend, String currentUserId) {
    if (!_friends.any((f) => f.id == friend.id)) {
      _friends.add(friend);
      _storage.saveFriends(currentUserId, _friends);
      notifyListeners();
    }
  }

  void removeFriend(String friendId, String currentUserId) {
    _friends.removeWhere((f) => f.id == friendId);
    _chatHistory.remove(friendId);
    _storage.saveFriends(currentUserId, _friends);
    notifyListeners();
  }

  List<MessageModel> getMessagesForFriend(String friendId) {
    return _chatHistory[friendId] ?? [];
  }

  MessageModel? getLastMessageForFriend(String friendId) {
    final list = _chatHistory[friendId];
    if (list == null || list.isEmpty) return null;
    return list.last;
  }

  Future<void> sendMessage({
    required String currentUserId,
    required String friendId,
    required String text,
    MessageType type = MessageType.text,
    String? avatarReaction,
    String? mediaUrl,
    String? fileName,
    String? fileSize,
    LocationPoint? locationData,
    String? audioDuration,
  }) async {
    final encResult = _crypto.encryptMessage(
      plainText: text,
      senderId: currentUserId,
      receiverId: friendId,
    );

    final msg = MessageModel(
      id: _uuid.v4(),
      senderId: currentUserId,
      receiverId: friendId,
      encryptedPayload: encResult['cipherText']!,
      iv: encResult['iv']!,
      decryptedContent: text,
      timestamp: DateTime.now(),
      isMine: true,
      isRead: false,
      type: type,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      locationData: locationData,
      audioDuration: audioDuration,
    );

    final currentList = _chatHistory[friendId] ?? [];
    currentList.add(msg);
    _chatHistory[friendId] = List.from(currentList);
    notifyListeners();

    await _storage.saveMessages(friendId, currentList);
  }

  void addReaction(String friendId, String messageId, String emoji) {
    final list = _chatHistory[friendId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      list[index] = list[index].copyWith(reactionEmoji: emoji);
      notifyListeners();
      _storage.saveMessages(friendId, list);
    }
  }
}
