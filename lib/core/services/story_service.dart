import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/story_model.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class StoryService extends ChangeNotifier {
  static const String _keyStories = 'piec_spatial_stories_v1';
  final Uuid _uuid = const Uuid();

  List<StoryModel> _stories = [];

  List<StoryModel> get stories => _stories;

  List<StoryModel> get userStories {
    return _stories.where((s) => s.userId == 'me' || s.userId.startsWith('user_')).toList();
  }

  List<StoryModel> get friendStories {
    return _stories.where((s) => s.userId != 'me' && !s.userId.startsWith('user_')).toList();
  }

  Future<void> init(UserModel? currentUser, ChatService chatService) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyStories);

    if (data != null && data.isNotEmpty) {
      try {
        final List decoded = jsonDecode(data);
        _stories = decoded.map((s) => StoryModel.fromMap(s)).toList();
      } catch (_) {
        _stories = [];
      }
    } else {
      _stories = [];
    }

    notifyListeners();
  }

  Future<StoryModel> postStory({
    required UserModel currentUser,
    required AvatarSceneType sceneType,
    required String caption,
    String? musicTrack,
    LocationPoint? locationPoint,
    String? squadId,
    Duration duration = const Duration(hours: 24),
  }) async {
    final newStory = StoryModel(
      id: 'story_${_uuid.v4()}',
      userId: currentUser.id,
      user: currentUser,
      sceneType: sceneType,
      caption: caption,
      musicTrack: musicTrack,
      locationPoint: locationPoint,
      squadId: squadId,
      createdAt: DateTime.now(),
      duration: duration,
    );

    _stories.insert(0, newStory);
    notifyListeners();
    await _saveStories();
    return newStory;
  }

  Future<StoryModel> createStory({
    required UserModel currentUser,
    required AvatarSceneType sceneType,
    required String caption,
    String? musicTrack,
    LocationPoint? locationPoint,
    int expiryHours = 24,
  }) =>
      postStory(
        currentUser: currentUser,
        sceneType: sceneType,
        caption: caption,
        musicTrack: musicTrack,
        locationPoint: locationPoint,
        duration: Duration(hours: expiryHours),
      );

  Future<void> deleteStory(String storyId) async {
    _stories.removeWhere((s) => s.id == storyId);
    notifyListeners();
    await _saveStories();
  }

  void markStoryAsViewed(String storyId, [String currentUserId = 'me']) {
    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      final viewers = List<String>.from(_stories[index].viewers);
      if (!viewers.contains(currentUserId)) {
        viewers.add(currentUserId);
        _stories[index] = _stories[index].copyWith(viewers: viewers, isViewed: true);
        notifyListeners();
        _saveStories();
      }
    }
  }

  void reactToStory(String storyId, String currentUserId, String emoji) {
    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      final reactions = Map<String, String>.from(_stories[index].reactions);
      reactions[currentUserId] = emoji;
      _stories[index] = _stories[index].copyWith(reactions: reactions);
      notifyListeners();
      _saveStories();
    }
  }

  void addReaction(String storyId, String userId, String emoji) => reactToStory(storyId, userId, emoji);

  Future<void> _saveStories() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_stories.map((s) => s.toMap()).toList());
    await prefs.setString(_keyStories, data);
  }
}
