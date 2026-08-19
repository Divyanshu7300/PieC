import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:piec/core/crypto/e2ee_engine.dart';
import 'package:piec/core/models/friend_request_model.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class FriendService extends ChangeNotifier {
  static const String _keyPendingRequests = 'piec_pending_requests';
  final E2EEEngine _crypto = E2EEEngine();
  final Uuid _uuid = const Uuid();

  List<FriendRequestModel> _pendingRequests = [];
  List<UserModel> _discoverableUsers = [];
  List<UserModel> _nearbyRadarUsers = [];

  List<FriendRequestModel> get pendingRequests => _pendingRequests;
  List<UserModel> get discoverableUsers => _discoverableUsers;
  List<UserModel> get nearbyRadarUsers => _nearbyRadarUsers;

  int get pendingCount => _pendingRequests.length;

  Future<void> init(String currentUserId) async {
    _discoverableUsers = [];
    _nearbyRadarUsers = [];

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyPendingRequests);
    if (data != null && data.isNotEmpty) {
      try {
        final List decoded = jsonDecode(data);
        _pendingRequests = decoded.map((item) => FriendRequestModel.fromMap(item)).toList();
      } catch (_) {
        _pendingRequests = [];
      }
    } else {
      _pendingRequests = [];
    }
    notifyListeners();
  }

  Future<void> sendKnockKnock({
    required UserModel currentUser,
    required UserModel targetUser,
    required String placeTitle,
  }) async {
    final newRequest = FriendRequestModel(
      id: _uuid.v4(),
      sender: currentUser,
      receiverId: targetUser.id,
      type: FriendRequestType.knockKnockMap,
      placeTitle: placeTitle,
      timestamp: DateTime.now(),
    );

    _pendingRequests.insert(0, newRequest);
    notifyListeners();
    await _savePendingRequests();
  }

  Future<void> sendRadarBump({
    required UserModel currentUser,
    required UserModel targetUser,
  }) async {
    final newRequest = FriendRequestModel(
      id: _uuid.v4(),
      sender: currentUser,
      receiverId: targetUser.id,
      type: FriendRequestType.nearbyRadar,
      timestamp: DateTime.now(),
    );

    _pendingRequests.insert(0, newRequest);
    notifyListeners();
    await _savePendingRequests();
  }

  Future<void> sendFriendRequest({
    required UserModel sender,
    required UserModel receiver,
    FriendRequestType type = FriendRequestType.usernameSearch,
    FriendPrivacyAccess privacyAccess = FriendPrivacyAccess.fullMapAccess,
  }) async {
    final newRequest = FriendRequestModel(
      id: _uuid.v4(),
      sender: sender,
      receiverId: receiver.id,
      type: type,
      privacyAccess: privacyAccess,
      timestamp: DateTime.now(),
    );

    _pendingRequests.insert(0, newRequest);
    notifyListeners();
    await _savePendingRequests();
  }

  Future<UserModel?> acceptFriendRequest(
    String requestId, {
    FriendPrivacyAccess access = FriendPrivacyAccess.fullMapAccess,
  }) async {
    final index = _pendingRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final sender = _pendingRequests[index].sender;
      _pendingRequests.removeAt(index);
      notifyListeners();
      await _savePendingRequests();
      return sender;
    }
    return null;
  }

  Future<void> declineFriendRequest(String requestId) async {
    _pendingRequests.removeWhere((r) => r.id == requestId);
    notifyListeners();
    await _savePendingRequests();
  }

  Future<UserModel?> acceptRequest(FriendRequestModel request) => acceptFriendRequest(request.id);
  Future<void> declineRequest(FriendRequestModel request) => declineFriendRequest(request.id);

  Future<void> _savePendingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_pendingRequests.map((r) => r.toMap()).toList());
    await prefs.setString(_keyPendingRequests, data);
  }

  List<UserModel> searchUsers(String query) {
    if (query.trim().isEmpty) return [];
    return _discoverableUsers.where((u) {
      final q = query.toLowerCase();
      return u.name.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          (u.phone != null && u.phone!.contains(q));
    }).toList();
  }

  List<UserModel> searchFriends(String query) => searchUsers(query);
}
