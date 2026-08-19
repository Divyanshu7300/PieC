import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/message_model.dart';
import 'package:piec/core/models/squad_model.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SquadService extends ChangeNotifier {
  static const String _keySquads = 'piec_squads_v1';
  static const String _keyActiveFilter = 'piec_active_squad_filter';

  final Uuid _uuid = const Uuid();

  List<SquadModel> _squads = [];
  String? _activeSquadFilterId; // null = Show All Friends
  final Map<String, List<MessageModel>> _squadMessages = {};

  List<SquadModel> get squads => _squads;
  String? get activeSquadFilterId => _activeSquadFilterId;

  SquadModel? get activeSquad {
    if (_activeSquadFilterId == null) return null;
    try {
      return _squads.firstWhere((s) => s.id == _activeSquadFilterId);
    } catch (_) {
      return null;
    }
  }

  Future<void> init(UserModel? currentUser, ChatService chatService) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keySquads);

    if (data != null && data.isNotEmpty) {
      try {
        final List decoded = jsonDecode(data);
        _squads = decoded.map((s) => SquadModel.fromMap(s)).toList();
      } catch (_) {
        _populateDefaultInitialSquads(currentUser, chatService);
      }
    } else {
      _populateDefaultInitialSquads(currentUser, chatService);
    }

    _activeSquadFilterId = prefs.getString(_keyActiveFilter);
    notifyListeners();
  }

  void _populateDefaultInitialSquads(UserModel? currentUser, ChatService chatService) {
    final friends = chatService.friends;
    final user = currentUser;

    final alex = friends.where((f) => f.id == 'friend_alex').toList();
    final sophia = friends.where((f) => f.id == 'friend_sophia').toList();
    final liam = friends.where((f) => f.id == 'friend_liam').toList();
    final zara = friends.where((f) => f.id == 'friend_zara').toList();

    _squads = [
      SquadModel(
        id: 'squad_gamers',
        name: 'Cyber Squad',
        emoji: '🎮',
        description: 'Late night gaming & spatial hangouts',
        adminId: user?.id ?? 'me',
        members: [
          if (user != null) user,
          ...alex,
          ...sophia,
          ...liam,
        ],
        meetupLocation: LocationPoint(
          title: 'VR Gaming Lounge & Cafe',
          address: 'Central Cyber Plaza, Floor 2',
          latitude: 28.6165,
          longitude: 77.2070,
          type: LocationType.hangout,
          updatedAt: DateTime.now(),
        ),
        colorHex: 0xFF00F0FF,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      SquadModel(
        id: 'squad_trip',
        name: 'Goa Road Trip 2026',
        emoji: '🏖️',
        description: 'Temporary trip circle (Only trip crew visible)',
        adminId: user?.id ?? 'me',
        members: [
          if (user != null) user,
          ...alex,
          ...zara,
        ],
        isTemporary: true,
        expiresAt: DateTime.now().add(const Duration(days: 3)),
        meetupLocation: LocationPoint(
          title: 'Highway Rest Stop & Fuel',
          address: 'Expressway Mile 42',
          latitude: 28.6210,
          longitude: 77.2180,
          type: LocationType.hangout,
          updatedAt: DateTime.now(),
        ),
        colorHex: 0xFFFF2A85,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      SquadModel(
        id: 'squad_work',
        name: 'Design Innovation Core',
        emoji: '💼',
        description: 'Office colleagues & project sprint',
        adminId: user?.id ?? 'me',
        members: [
          if (user != null) user,
          ...sophia,
          ...liam,
        ],
        colorHex: 0xFF10B981,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];

    _save();
  }

  Future<void> selectSquadFilter(String? squadId) async {
    _activeSquadFilterId = squadId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (squadId == null) {
      await prefs.remove(_keyActiveFilter);
    } else {
      await prefs.setString(_keyActiveFilter, squadId);
    }
  }

  Future<void> createSquad({
    required String name,
    required String emoji,
    String description = '',
    required UserModel currentUser,
    required List<UserModel> selectedFriends,
    LocationPoint? initialMeetupPin,
    bool isTemporary = false,
    int colorHex = 0xFF00F0FF,
  }) async {
    final newSquad = SquadModel(
      id: 'squad_${_uuid.v4().substring(0, 8)}',
      name: name,
      emoji: emoji,
      description: description,
      adminId: currentUser.id,
      members: [currentUser, ...selectedFriends],
      meetupLocation: initialMeetupPin,
      isTemporary: isTemporary,
      expiresAt: isTemporary ? DateTime.now().add(const Duration(hours: 24)) : null,
      colorHex: colorHex,
      createdAt: DateTime.now(),
    );

    _squads.insert(0, newSquad);
    _activeSquadFilterId = newSquad.id; // Automatically focus on new squad on map
    notifyListeners();
    await _save();
  }

  Future<void> setSquadMeetupPin(String squadId, LocationPoint pin) async {
    final index = _squads.indexWhere((s) => s.id == squadId);
    if (index != -1) {
      _squads[index] = _squads[index].copyWith(meetupLocation: pin);
      notifyListeners();
      await _save();
    }
  }

  Future<void> removeSquadMeetupPin(String squadId) async {
    final index = _squads.indexWhere((s) => s.id == squadId);
    if (index != -1) {
      _squads[index] = SquadModel(
        id: _squads[index].id,
        name: _squads[index].name,
        emoji: _squads[index].emoji,
        description: _squads[index].description,
        adminId: _squads[index].adminId,
        members: _squads[index].members,
        meetupLocation: null,
        isTemporary: _squads[index].isTemporary,
        expiresAt: _squads[index].expiresAt,
        colorHex: _squads[index].colorHex,
        createdAt: _squads[index].createdAt,
      );
      notifyListeners();
      await _save();
    }
  }

  List<MessageModel> getSquadMessages(String squadId) {
    return _squadMessages[squadId] ?? [
      MessageModel(
        id: 'msg_squad_welcome',
        senderId: 'squad_system',
        receiverId: squadId,
        encryptedPayload: 'Welcome to the Squad Spatial Room! 🚀',
        iv: '',
        decryptedContent: 'Welcome to the Squad Spatial Room! All group members are synced on map 🚀',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isMine: false,
      ),
    ];
  }

  Future<void> sendSquadMessage({
    required String squadId,
    required String senderId,
    required String text,
    String? avatarReaction,
  }) async {
    if (text.trim().isEmpty) return;

    final msg = MessageModel(
      id: _uuid.v4(),
      senderId: senderId,
      receiverId: squadId,
      encryptedPayload: text.trim(),
      iv: '',
      decryptedContent: text.trim(),
      timestamp: DateTime.now(),
      isMine: true,
      avatarReaction: avatarReaction,
    );

    final list = _squadMessages[squadId] ?? [];
    list.add(msg);
    _squadMessages[squadId] = List.from(list);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _squads.map((s) => s.toMap()).toList();
    await prefs.setString(_keySquads, jsonEncode(list));
  }
}
