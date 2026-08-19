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
        _populateDefaultInitialStories(currentUser, chatService);
      }
    } else {
      _populateDefaultInitialStories(currentUser, chatService);
    }

    notifyListeners();
  }

  void _populateDefaultInitialStories(UserModel? currentUser, ChatService chatService) {
    final friends = chatService.friends;
    final sophiaList = friends.where((f) => f.id == 'friend_sophia').toList();
    final alexList = friends.where((f) => f.id == 'friend_alex').toList();
    final liamList = friends.where((f) => f.id == 'friend_liam').toList();

    _stories = [
      if (sophiaList.isNotEmpty)
        StoryModel(
          id: 'story_sophia_1',
          userId: sophiaList.first.id,
          user: sophiaList.first,
          sceneType: AvatarSceneType.gamingRig,
          caption: 'Grinding new 3D spatial map levels! Who is down for squad match? 🎮⚡',
          musicTrack: 'Cyberpunk Neon Pulse 🎵',
          locationPoint: LocationPoint(
            title: 'Design Matrix HQ',
            address: 'Cyber Tech Park Level 7',
            latitude: 28.6240,
            longitude: 77.2110,
            type: LocationType.office,
            updatedAt: DateTime.now(),
          ),
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          reactions: {'me': '🔥'},
        ),
      if (alexList.isNotEmpty)
        StoryModel(
          id: 'story_alex_1',
          userId: alexList.first.id,
          user: alexList.first,
          sceneType: AvatarSceneType.cafeCoffee,
          caption: 'Morning brew at the rooftop ☕ Check out my 3D outfit glow ✨',
          musicTrack: 'Lo-Fi Tokyo Chill 🎵',
          locationPoint: LocationPoint(
            title: "Alex's Penthouse",
            address: 'Skyline Tower, Apt 402',
            latitude: 28.6180,
            longitude: 77.2140,
            type: LocationType.home,
            updatedAt: DateTime.now(),
          ),
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          reactions: {'me': '❤️'},
        ),
      if (liamList.isNotEmpty)
        StoryModel(
          id: 'story_liam_1',
          userId: liamList.first.id,
          user: liamList.first,
          sceneType: AvatarSceneType.carDrive,
          caption: 'Night highway cruising with cyber synthwave vibes on repeat 🚗💨',
          musicTrack: 'Midnight Expressway Synth 🎵',
          locationPoint: LocationPoint(
            title: 'Central Highway Mile 18',
            address: 'Expressway Route 4',
            latitude: 28.6165,
            longitude: 77.2070,
            type: LocationType.hangout,
            updatedAt: DateTime.now(),
          ),
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
    ];

    _save();
  }

  Future<void> postStory({
    required UserModel currentUser,
    required AvatarSceneType sceneType,
    required String caption,
    String? musicTrack,
    LocationPoint? locationPoint,
    String? squadId,
    Duration duration = const Duration(hours: 24),
  }) async {
    final newStory = StoryModel(
      id: 'story_${_uuid.v4().substring(0, 8)}',
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
    await _save();
  }

  void markStoryAsViewed(String storyId) {
    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index != -1 && !_stories[index].isViewed) {
      _stories[index] = _stories[index].copyWith(isViewed: true);
      notifyListeners();
      _save();
    }
  }

  void reactToStory(String storyId, String emoji, String currentUserId) {
    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      final updatedReactions = Map<String, String>.from(_stories[index].reactions);
      updatedReactions[currentUserId] = emoji;
      _stories[index] = _stories[index].copyWith(reactions: updatedReactions);
      notifyListeners();
      _save();
    }
  }

  List<StoryModel> getStoriesForMap() {
    return _stories.where((s) => s.locationPoint != null).toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _stories.map((s) => s.toMap()).toList();
    await prefs.setString(_keyStories, jsonEncode(list));
  }
}
