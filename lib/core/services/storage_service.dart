import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/models/message_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _keyCurrentUser = 'piec_current_user';
  static const String _keyMessagesPrefix = 'piec_messages_';
  static const String _keyGhostMode = 'piec_ghost_mode';

  Future<void> saveCurrentUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUser, user.toJson());
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyCurrentUser);
    if (data == null || data.isEmpty) return null;
    try {
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
  }

  Future<void> saveMessages(String chatPartnerId, List<MessageModel> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = messages.map((m) => m.toMap()).toList();
    await prefs.setString('$_keyMessagesPrefix$chatPartnerId', jsonEncode(listJson));
  }

  Future<List<MessageModel>> getMessages(String chatPartnerId, String currentUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_keyMessagesPrefix$chatPartnerId');
    if (data == null || data.isEmpty) return [];
    try {
      final List decoded = jsonDecode(data);
      return decoded
          .map<MessageModel>((m) => MessageModel.fromMap(m as Map<String, dynamic>, currentUserId: currentUserId))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static const String _keyFriendsPrefix = 'piec_friends_';

  Future<void> saveFriends(String currentUserId, List<UserModel> friends) async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = friends.map((f) => f.toMap()).toList();
    await prefs.setString('$_keyFriendsPrefix$currentUserId', jsonEncode(listJson));
  }

  Future<List<UserModel>> getFriends(String currentUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_keyFriendsPrefix$currentUserId');
    if (data == null || data.isEmpty) return [];
    try {
      final List decoded = jsonDecode(data);
      return decoded.map<UserModel>((f) => UserModel.fromMap(f as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setGhostMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGhostMode, enabled);
  }

  Future<bool> getGhostMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGhostMode) ?? false;
  }
}
