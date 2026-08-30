import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:piec/core/models/friend_request_model.dart';
import 'package:piec/core/models/user_model.dart';

class FriendService extends ChangeNotifier {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  List<FriendRequestModel> _pendingRequests = [];
  List<UserModel> _discoverableUsers = [];
  List<UserModel> _nearbyRadarUsers = [];
  String? _currentUserId;

  List<FriendRequestModel> get pendingRequests => _pendingRequests;
  List<UserModel> get discoverableUsers => _discoverableUsers;
  List<UserModel> get nearbyRadarUsers => _nearbyRadarUsers;

  int get pendingCount => _pendingRequests.length;

  Future<void> init(String currentUserId) async {
    if (_auth.currentUser?.uid != currentUserId) return;
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
    await sendFriendRequest(
      sender: currentUser,
      receiver: targetUser,
      type: FriendRequestType.knockKnockMap,
      placeTitle: placeTitle,
    );
  }

  Future<void> sendRadarBump({
    required UserModel currentUser,
    required UserModel targetUser,
  }) async {
    await sendFriendRequest(
      sender: currentUser,
      receiver: targetUser,
      type: FriendRequestType.nearbyRadar,
    );
  }

  Future<void> sendFriendRequest({
    required UserModel sender,
    required UserModel receiver,
    FriendRequestType type = FriendRequestType.usernameSearch,
    FriendPrivacyAccess privacyAccess = FriendPrivacyAccess.fullMapAccess,
    String? placeTitle,
  }) async {
    if (_auth.currentUser?.uid != sender.id) {
      throw StateError('You must be signed in to send a friend request.');
    }
    if (sender.id == receiver.id) {
      throw ArgumentError('You cannot add yourself as a friend.');
    }
    final requestId = '${sender.id}_${receiver.id}';
    final newRequest = FriendRequestModel(
      id: requestId,
      sender: sender,
      receiverId: receiver.id,
      type: type,
      placeTitle: placeTitle,
      privacyAccess: privacyAccess,
      timestamp: DateTime.now(),
    );

    // A deterministic id prevents duplicate requests from repeated taps.
    await _db.collection('users').doc(receiver.id).collection('friend_requests').doc(requestId).set({
      ...newRequest.toMap(),
      'id': requestId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserModel?> acceptFriendRequest(
    String requestId, {
    FriendPrivacyAccess access = FriendPrivacyAccess.fullMapAccess,
  }) async {
    final currentUid = _currentUserId;
    if (currentUid == null || _auth.currentUser?.uid != currentUid) {
      throw StateError('You must be signed in to accept a friend request.');
    }
    final index = _pendingRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return null;
    final req = _pendingRequests[index];
    final requestRef = _db.collection('users').doc(currentUid).collection('friend_requests').doc(requestId);
    final ownFriendRef = _db.collection('users').doc(currentUid).collection('friends').doc(req.sender.id);
    final peerFriendRef = _db.collection('users').doc(req.sender.id).collection('friends').doc(currentUid);
    final myProfile = await _db.collection('users').doc(currentUid).get();
    if (!myProfile.exists) throw StateError('Your profile is not ready yet.');

    await _db.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) throw StateError('This friend request has already been handled.');
      final data = requestSnapshot.data()!;
      if (data['receiverId'] != currentUid || (data['sender'] as Map?)?['id'] != req.sender.id) {
        throw StateError('Invalid friend request.');
      }
      transaction.set(ownFriendRef, _friendSnapshot(req.sender, requestId, access));
      transaction.set(peerFriendRef, _friendSnapshot(UserModel.fromFirestore(myProfile.data()!, currentUid), requestId, access));
      transaction.delete(requestRef);
    });
    _pendingRequests.removeAt(index);
    notifyListeners();
    return req.sender;
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

  Map<String, dynamic> _friendSnapshot(UserModel user, String requestId, FriendPrivacyAccess access) => {
    ...user.toFirestore(),
    'uid': user.id,
    'requestId': requestId,
    'privacyAccess': access.name,
    'addedAt': FieldValue.serverTimestamp(),
  };
}
