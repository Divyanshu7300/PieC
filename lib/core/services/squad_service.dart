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
        _squads = [];
      }
    } else {
      _squads = [];
    }

    _activeSquadFilterId = prefs.getString(_keyActiveFilter);
    notifyListeners();
  }

  void setActiveFilter(String? squadId) async {
    _activeSquadFilterId = squadId;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (squadId == null) {
      await prefs.remove(_keyActiveFilter);
    } else {
      await prefs.setString(_keyActiveFilter, squadId);
    }
  }

  void selectSquadFilter(String? squadId) => setActiveFilter(squadId);

  Future<SquadModel> createSquad({
    required String name,
    required String emoji,
    UserModel? currentUser,
    List<UserModel>? selectedFriends,
    List<UserModel>? members,
    LocationPoint? initialMeetupPin,
    LocationPoint? meetupLocation,
    bool isTemporary = false,
  }) async {
    final friendsList = selectedFriends ?? members ?? [];
    final allMembers = List<UserModel>.from(friendsList);
    if (currentUser != null && !allMembers.any((m) => m.id == currentUser.id)) {
      allMembers.insert(0, currentUser);
    }

    final newSquad = SquadModel(
      id: 'squad_${_uuid.v4()}',
      name: name,
      emoji: emoji,
      adminId: currentUser?.id ?? (allMembers.isNotEmpty ? allMembers.first.id : 'admin'),
      members: allMembers,
      meetupLocation: initialMeetupPin ?? meetupLocation,
      isTemporary: isTemporary,
      expiresAt: isTemporary ? DateTime.now().add(const Duration(hours: 24)) : null,
      createdAt: DateTime.now(),
    );

    _squads.add(newSquad);
    notifyListeners();
    await _saveSquads();
    return newSquad;
  }

  Future<void> deleteSquad(String squadId) async {
    _squads.removeWhere((s) => s.id == squadId);
    if (_activeSquadFilterId == squadId) {
      _activeSquadFilterId = null;
    }
    notifyListeners();
    await _saveSquads();
  }

  Future<void> updateMeetupLocation(String squadId, LocationPoint? location) async {
    final index = _squads.indexWhere((s) => s.id == squadId);
    if (index != -1) {
      _squads[index] = _squads[index].copyWith(meetupLocation: location);
      notifyListeners();
      await _saveSquads();
    }
  }

  List<MessageModel> getSquadMessages(String squadId) {
    return _squadMessages[squadId] ?? [];
  }

  void sendSquadMessage({
    required String squadId,
    String? senderId,
    UserModel? sender,
    required String text,
    String? avatarReaction,
  }) {
    final sId = senderId ?? sender?.id ?? 'me';
    final msg = MessageModel(
      id: _uuid.v4(),
      senderId: sId,
      receiverId: squadId,
      encryptedPayload: '',
      iv: '',
      decryptedContent: text,
      timestamp: DateTime.now(),
      isMine: true,
      avatarReaction: avatarReaction,
    );

    final list = _squadMessages[squadId] ?? [];
    list.add(msg);
    _squadMessages[squadId] = List.from(list);
    notifyListeners();
  }

  Future<void> _saveSquads() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_squads.map((s) => s.toMap()).toList());
    await prefs.setString(_keySquads, data);
  }
}
