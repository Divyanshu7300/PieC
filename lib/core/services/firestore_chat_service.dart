import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/message_model.dart';
import '../models/user_model.dart';

/// Firestore-backed one-to-one chat. Firebase encrypts traffic and data at rest;
/// this class deliberately does not make an end-to-end-encryption claim.
class FirestoreChatService extends ChangeNotifier {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  String _chatRoomId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  void _requireCurrentUser(String uid) {
    if (_auth.currentUser?.uid != uid) throw StateError('You must be signed in as the sending user.');
  }

  Future<void> sendMessage({
    required String senderId, required String receiverId, required String text,
    MessageType type = MessageType.text, String? mediaUrl, String? fileName, String? fileSize,
  }) async {
    _requireCurrentUser(senderId);
    final roomId = _chatRoomId(senderId, receiverId);
    final message = _db.collection('chats').doc(roomId).collection('messages').doc(_uuid.v4());
    final batch = _db.batch();
    batch.set(message, {
      'id': message.id, 'senderId': senderId, 'receiverId': receiverId, 'content': text,
      'createdAt': FieldValue.serverTimestamp(), 'isRead': false, 'type': type.name,
      'mediaUrl': mediaUrl, 'fileName': fileName, 'fileSize': fileSize,
    });
    batch.set(_db.collection('chats').doc(roomId), {
      'participants': [senderId, receiverId],
      'lastMessagePreview': type == MessageType.text ? text.substring(0, text.length.clamp(0, 120)) : 'Sent ${type.name}',
      'lastMessageAt': FieldValue.serverTimestamp(), 'lastSenderId': senderId,
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Stream<List<MessageModel>> messagesStream(String uid1, String uid2, String currentUserId, {int pageSize = 50}) {
    final roomId = _chatRoomId(uid1, uid2);
    return _db.collection('chats').doc(roomId).collection('messages').orderBy('createdAt', descending: true).limit(pageSize).snapshots().map((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : DateTime.now();
        return MessageModel(
          id: data['id'] as String? ?? doc.id, senderId: data['senderId'] as String? ?? '', receiverId: data['receiverId'] as String? ?? '',
          encryptedPayload: '', iv: '', decryptedContent: data['content'] as String? ?? '[Legacy protected message]', timestamp: timestamp,
          isMine: data['senderId'] == currentUserId, isRead: data['isRead'] as bool? ?? false,
          type: MessageType.values.firstWhere((e) => e.name == data['type'], orElse: () => MessageType.text),
          mediaUrl: data['mediaUrl'] as String?, fileName: data['fileName'] as String?, fileSize: data['fileSize'] as String?,
        );
      }).toList();
      return messages.reversed.toList();
    });
  }

  Future<void> markAsRead(String uid1, String uid2, String currentUserId) async {
    _requireCurrentUser(currentUserId);
    final roomId = _chatRoomId(uid1, uid2);
    final unread = await _db.collection('chats').doc(roomId).collection('messages').where('receiverId', isEqualTo: currentUserId).where('isRead', isEqualTo: false).limit(400).get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread.docs) { batch.update(doc.reference, {'isRead': true, 'readAt': FieldValue.serverTimestamp()}); }
    await batch.commit();
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists && doc.data() != null ? UserModel.fromFirestore(doc.data()!, uid) : null;
  }

  Future<List<UserModel>> searchRegisteredUsers(String query, String currentUserId) async {
    final normalized = query.trim().toLowerCase().replaceFirst('@', '');
    if (normalized.isEmpty) return [];
    final result = await _db.collection('users').where('usernameLower', isEqualTo: normalized).limit(10).get();
    return result.docs.where((doc) => doc.id != currentUserId).map((doc) => UserModel.fromFirestore(doc.data(), doc.id)).toList();
  }

  Stream<List<UserModel>> friendsStream(String userId) => _db.collection('users').doc(userId).collection('friends').orderBy('addedAt', descending: true).snapshots().map((snap) => snap.docs.map((doc) => UserModel.fromFirestore(doc.data(), doc.id)).toList());
}
