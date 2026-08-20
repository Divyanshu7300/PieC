import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:piec/core/crypto/e2ee_engine.dart';
import 'package:piec/core/models/friend_request_model.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class FriendService extends ChangeNotifier {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  static const String _keyPendingRequests = 'piec_pending_requests';
  final E2EEEngine _crypto = E2EEEngine();
  final Uuid _uuid = const Uuid();

  List<FriendRequestModel> _pendingRequests = [];
  List<UserModel> _discoverableUsers = [];
  List<UserModel> _nearbyRadarUsers = [];
  String? _currentUserId;

  List<FriendRequestModel> get pendingRequests => _pendingRequests;
  List<UserModel> get discoverableUsers => _discoverableUsers;
  List<UserModel> get nearbyRadarUsers => _nearbyRadarUsers;

  int get pendingCount => _pendingRequests.length;

  Future<void> init(String currentUserId) async {
    _currentUserId = currentUserId;
    _discoverableUsers = [];
    _nearbyRadarUsers = [];

    // 1. Listen to real incoming friend requests from Cloud Firestore
    try {
      _db
          .collection('users')
          .doc(currentUserId)
          .collection('friend_requests')
          .snapshots()
          .listen((snap) {
        _pendingRequests = snap.docs.map((doc) {
          return FriendRequestModel.fromMap(doc.data());
        }).where((req) => req.sender.id != currentUserId).toList();
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Friend requests firestore listener error: $e');
    }
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

    try {
      await _db
          .collection('users')
          .doc(targetUser.id)
          .collection('friend_requests')
          .doc(newRequest.id)
          .set(newRequest.toMap());
    } catch (e) {
      debugPrint('sendKnockKnock error: $e');
    }
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

    try {
      await _db
          .collection('users')
          .doc(targetUser.id)
          .collection('friend_requests')
          .doc(newRequest.id)
          .set(newRequest.toMap());
    } catch (e) {
      debugPrint('sendRadarBump error: $e');
    }
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

    // Save to receiver's Firestore inbox
    try {
      await _db
          .collection('users')
          .doc(receiver.id)
          .collection('friend_requests')
          .doc(newRequest.id)
          .set(newRequest.toMap());
    } catch (e) {
      debugPrint('Error sending friend request to Firestore: $e');
    }
  }

  Future<UserModel?> acceptFriendRequest(
    String requestId, {
    FriendPrivacyAccess access = FriendPrivacyAccess.fullMapAccess,
  }) async {
    final index = _pendingRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final req = _pendingRequests[index];
      final sender = req.sender;
      _pendingRequests.removeAt(index);
      notifyListeners();

      if (_currentUserId != null) {
        try {
          await _db
              .collection('users')
              .doc(_currentUserId!)
              .collection('friend_requests')
              .doc(requestId)
              .delete();
        } catch (_) {}
      }
      return sender;
    }
    return null;
  }

  Future<void> declineFriendRequest(String requestId) async {
    _pendingRequests.removeWhere((r) => r.id == requestId);
    notifyListeners();
    if (_currentUserId != null) {
      try {
        await _db
            .collection('users')
            .doc(_currentUserId!)
            .collection('friend_requests')
            .doc(requestId)
            .delete();
      } catch (_) {}
    }
  }

  Future<UserModel?> acceptRequest(FriendRequestModel request) => acceptFriendRequest(request.id);
  Future<void> declineRequest(FriendRequestModel request) => declineFriendRequest(request.id);

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
