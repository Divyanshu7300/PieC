import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../crypto/e2ee_engine.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class FirestoreChatService extends ChangeNotifier {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final E2EEEngine _crypto = E2EEEngine();


  String _chatRoomId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // Send an E2EE encrypted real message to Firestore
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? fileName,
    String? fileSize,
  }) async {
    final roomId = _chatRoomId(senderId, receiverId);
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();

    // Client-side AES-256 encryption
    final encResult = _crypto.encryptMessage(
      plainText: text,
      senderId: senderId,
      receiverId: receiverId,
    );

    final msgData = {
      'id': msgId,
      'senderId': senderId,
      'receiverId': receiverId,
      'encryptedPayload': encResult['cipherText'] ?? '',
      'iv': encResult['iv'] ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
    };

    await _db
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .doc(msgId)
        .set(msgData);

    // Update last message preview in chat room (preview is also encrypted or safe label)
    await _db.collection('chats').doc(roomId).set({
      'participants': [senderId, receiverId],
      'lastMessageEncrypted': encResult['cipherText'] ?? '',
      'lastMessageIv': encResult['iv'] ?? '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    }, SetOptions(merge: true));
  }

  // Stream of real decrypted messages
  Stream<List<MessageModel>> messagesStream(String uid1, String uid2, String currentUserId) {
    final roomId = _chatRoomId(uid1, uid2);
    return _db
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      final List<MessageModel> list = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final sId = data['senderId'] ?? '';
        final rId = data['receiverId'] ?? '';
        final cipher = data['encryptedPayload'] ?? '';
        final iv = data['iv'] ?? '';

        // Decrypt on device
        String plain = '';
        if (cipher.isNotEmpty) {
          plain = _crypto.decryptMessage(
            cipherText: cipher,
            ivBase64: iv,
            senderId: sId,
            receiverId: rId,
          );
        }

        DateTime ts = DateTime.now();
        if (data['timestamp'] is Timestamp) {
          ts = (data['timestamp'] as Timestamp).toDate();
        }

        list.add(MessageModel(
          id: data['id'] ?? doc.id,
          senderId: sId,
          receiverId: rId,
          encryptedPayload: cipher,
          iv: iv,
          decryptedContent: plain,
          timestamp: ts,
          isMine: sId == currentUserId,
          isRead: data['isRead'] ?? false,
          type: MessageType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => MessageType.text,
          ),
          mediaUrl: data['mediaUrl'],
          fileName: data['fileName'],
          fileSize: data['fileSize'],
          reactionEmoji: data['reactionEmoji'],
          avatarReaction: data['avatarReaction'],
        ));
      }
      return list;
    });
  }

  // Mark messages as read
  Future<void> markAsRead(String uid1, String uid2, String currentUserId) async {
    final roomId = _chatRoomId(uid1, uid2);
    final unread = await _db
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Get list of chat rooms for current user
  Stream<List<Map<String, dynamic>>> chatRoomsStream(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc.data()!, uid);
      }
    } catch (e) {
      debugPrint('getUserById error: $e');
    }
    return null;
  }

  // Search real registered users in Firestore
  Future<List<UserModel>> searchRegisteredUsers(String query, String currentUserId) async {
    try {
      final snap = await _db.collection('users').get();
      final allUsers = snap.docs
          .where((d) => d.id != currentUserId)
          .map((d) => UserModel.fromFirestore(d.data(), d.id))
          .toList();

      if (query.trim().isEmpty) {
        return allUsers; // Show all users by default
      }

      final q = query.trim().toLowerCase().replaceAll('@', '');
      return allUsers.where((u) =>
          u.name.toLowerCase().contains(q) ||
          u.username.toLowerCase().replaceAll('@', '').contains(q) ||
          (u.phone != null && u.phone!.contains(q)) ||
          (u.email != null && u.email!.toLowerCase().contains(q))).toList();
    } catch (e) {
      debugPrint('searchRegisteredUsers error: $e');
      return [];
    }
  }

  // Stream friends list with live data
  Stream<List<UserModel>> friendsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .asyncMap((snap) async {
      final List<UserModel> friends = [];
      for (final doc in snap.docs) {
        final uid = doc.data()['uid'] as String?;
        if (uid != null) {
          final user = await getUserById(uid);
          if (user != null) friends.add(user);
        }
      }
      return friends;
    });
  }

  // Cross-device Firestore friend connection
  Future<void> addFriendToFirestore({
    required String currentUserId,
    required UserModel friend,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friend.id)
          .set({
        'uid': friend.id,
        'name': friend.name,
        'username': friend.username,
        'phone': friend.phone,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Reciprocal connection
      final currentDoc = await _db.collection('users').doc(currentUserId).get();
      if (currentDoc.exists && currentDoc.data() != null) {
        final data = currentDoc.data()!;
        await _db
            .collection('users')
            .doc(friend.id)
            .collection('friends')
            .doc(currentUserId)
            .set({
          'uid': currentUserId,
          'name': data['name'] ?? 'PieC Friend',
          'username': data['username'] ?? 'friend',
          'phone': data['phone'],
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('addFriendToFirestore error: $e');
    }
  }
}
