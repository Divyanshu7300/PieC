import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:piec/core/crypto/e2ee_engine.dart';
import 'package:piec/core/models/avatar_config.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/message_model.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class ChatService extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final E2EEEngine _crypto = E2EEEngine();
  final Uuid _uuid = const Uuid();

  List<UserModel> _friends = [];
  final Map<String, List<MessageModel>> _chatHistory = {};
  final Map<String, bool> _typingUsers = {};
  final Map<String, String> _activeAvatarReactions = {};

  List<UserModel> get friends => _friends;
  Map<String, bool> get typingUsers => _typingUsers;
  Map<String, String> get activeAvatarReactions => _activeAvatarReactions;

  Future<void> init(String currentUserId) async {
    _loadMockFriends();
    for (final friend in _friends) {
      final cached = await _storage.getMessages(friend.id, currentUserId);
      if (cached.isNotEmpty) {
        final decryptedList = cached.map((msg) {
          final decrypted = _crypto.decryptMessage(
            cipherText: msg.encryptedPayload,
            ivBase64: msg.iv,
            senderId: msg.senderId,
            receiverId: msg.receiverId,
          );
          return msg.copyWith(decryptedContent: decrypted);
        }).toList();
        _chatHistory[friend.id] = decryptedList;
      } else {
        _populateDefaultInitialChat(friend, currentUserId);
      }
    }
    notifyListeners();
  }

  void _loadMockFriends() {
    _friends = [
      UserModel(
        id: 'friend_alex',
        name: 'Alex Vance',
        username: 'cyber_alex',
        statusText: 'At Home chilling 🍕',
        isOnline: true,
        batteryPercentage: 82,
        isCharging: false,
        privacyMode: LocationPrivacyMode.precise,
        publicKey: _crypto.generatePublicKey('friend_alex'),
        lastActive: DateTime.now(),
        avatarConfig: const AvatarConfig(
          hairStyle: HairStyle.cyberPunkFade,
          hairBaseColorHex: 0xFF121826,
          hairHighlightColorHex: 0xFFFF2A85,
          irisColor: IrisColor.cyberCyan,
          facialHair: FacialHair.stubbleShadow,
          outfitStyle: OutfitStyle.cyberHoodieWithGlow,
          outfitPrimaryColorHex: 0xFFFF2A85,
          outfitSecondaryColorHex: 0xFF00F0FF,
          accessory: AvatarAccessory.studioHeadphonesLed,
          auraEffect: AvatarAuraEffect.none,
          pose: AvatarPose.wavingHand,
          glowColorHex: 0xFFFF2A85,
        ),
        homeLocation: LocationPoint(
          title: "Alex's Penthouse",
          address: 'Skyline Tower, Apt 402',
          latitude: 28.6180,
          longitude: 77.2140,
          type: LocationType.home,
          updatedAt: DateTime.now(),
        ),
        officeLocation: LocationPoint(
          title: 'VR Game Studio',
          address: 'Metaverse Labs, Tech Block',
          latitude: 28.6250,
          longitude: 77.2210,
          type: LocationType.office,
          updatedAt: DateTime.now(),
        ),
        liveLocation: LocationPoint(
          title: "Alex's Penthouse",
          address: 'Skyline Tower, Apt 402',
          latitude: 28.6180,
          longitude: 77.2140,
          type: LocationType.home,
          updatedAt: DateTime.now(),
        ),
      ),
      UserModel(
        id: 'friend_sophia',
        name: 'Sophia Chen',
        username: 'sophia_neon',
        statusText: 'Working at Office 💼',
        isOnline: true,
        batteryPercentage: 4,
        isCharging: false,
        lastKnownBeaconTime: DateTime.now().subtract(const Duration(minutes: 6)),
        lastKnownBeaconAddress: 'Design Matrix HQ Level 7 (Battery ran out)',
        privacyMode: LocationPrivacyMode.precise,
        publicKey: _crypto.generatePublicKey('friend_sophia'),
        lastActive: DateTime.now().subtract(const Duration(minutes: 8)),
        avatarConfig: const AvatarConfig(
          hairStyle: HairStyle.longFlowyWavy,
          hairBaseColorHex: 0xFF1E112A,
          hairHighlightColorHex: 0xFF00F0FF,
          irisColor: IrisColor.neonEmerald,
          outfitStyle: OutfitStyle.bomberJacketLeather,
          outfitPrimaryColorHex: 0xFF00F0FF,
          outfitSecondaryColorHex: 0xFFB026FF,
          accessory: AvatarAccessory.royalCyberCrown,
          auraEffect: AvatarAuraEffect.none,
          pose: AvatarPose.peaceSign,
          glowColorHex: 0xFF00F0FF,
        ),
        homeLocation: LocationPoint(
          title: "Sophia's Villa",
          address: 'Maple Creek Blvd #12',
          latitude: 28.6090,
          longitude: 77.2030,
          type: LocationType.home,
          updatedAt: DateTime.now(),
        ),
        officeLocation: LocationPoint(
          title: 'Design Matrix HQ',
          address: 'Cyber Tech Park Level 7',
          latitude: 28.6240,
          longitude: 77.2110,
          type: LocationType.office,
          updatedAt: DateTime.now(),
        ),
        liveLocation: LocationPoint(
          title: 'Design Matrix HQ',
          address: 'Cyber Tech Park Level 7',
          latitude: 28.6240,
          longitude: 77.2110,
          type: LocationType.office,
          updatedAt: DateTime.now(),
        ),
      ),
      UserModel(
        id: 'friend_liam',
        name: 'Liam Walker',
        username: 'liam_drift',
        statusText: 'Hanging at Cafe ☕',
        isOnline: true,
        batteryPercentage: 94,
        isCharging: true,
        privacyMode: LocationPrivacyMode.blurred,
        publicKey: _crypto.generatePublicKey('friend_liam'),
        lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
        avatarConfig: const AvatarConfig(
          hairStyle: HairStyle.pompadourVolume,
          hairBaseColorHex: 0xFF2D1E12,
          hairHighlightColorHex: 0xFFFFD600,
          irisColor: IrisColor.amberGold,
          facialHair: FacialHair.cyberGoatee,
          outfitStyle: OutfitStyle.neonTechArmor,
          outfitPrimaryColorHex: 0xFFFF6B00,
          outfitSecondaryColorHex: 0xFFFFD600,
          accessory: AvatarAccessory.cyberVisorHolo,
          auraEffect: AvatarAuraEffect.none,
          glowColorHex: 0xFFFFD600,
        ),
        homeLocation: LocationPoint(
          title: "Liam's Garage",
          address: 'Westwood Avenue 99',
          latitude: 28.6110,
          longitude: 77.2190,
          type: LocationType.home,
          updatedAt: DateTime.now(),
        ),
        officeLocation: LocationPoint(
          title: 'Speed Robotics',
          address: 'North Industrial Park',
          latitude: 28.6280,
          longitude: 77.2050,
          type: LocationType.office,
          updatedAt: DateTime.now(),
        ),
        liveLocation: LocationPoint(
          title: 'Cyber Cafe Express',
          address: 'Central Boulevard Area',
          latitude: 28.6165,
          longitude: 77.2070,
          type: LocationType.hangout,
          updatedAt: DateTime.now(),
        ),
      ),
      UserModel(
        id: 'friend_zara',
        name: 'Zara Malik',
        username: 'zara_cyber',
        statusText: 'Listening to Music 🎧',
        isOnline: false,
        batteryPercentage: 65,
        isCharging: false,
        privacyMode: LocationPrivacyMode.precise,
        publicKey: _crypto.generatePublicKey('friend_zara'),
        lastActive: DateTime.now().subtract(const Duration(hours: 3)),
        avatarConfig: const AvatarConfig(
          hairStyle: HairStyle.undercutSlick,
          hairBaseColorHex: 0xFF1C1427,
          hairHighlightColorHex: 0xFFB026FF,
          irisColor: IrisColor.electricPurple,
          outfitStyle: OutfitStyle.cozyOversizedSweater,
          outfitPrimaryColorHex: 0xFF8B5CF6,
          outfitSecondaryColorHex: 0xFFFF2A85,
          accessory: AvatarAccessory.goldCyberChain,
          auraEffect: AvatarAuraEffect.none,
          glowColorHex: 0xFF8B5CF6,
        ),
        homeLocation: LocationPoint(
          title: "Zara's Cozy Place",
          address: 'Green Hills Sector 2',
          latitude: 28.6050,
          longitude: 77.2120,
          type: LocationType.home,
          updatedAt: DateTime.now(),
        ),
        officeLocation: LocationPoint(
          title: 'AI Security Corp',
          address: 'Tower B, Innovation City',
          latitude: 28.6290,
          longitude: 77.2180,
          type: LocationType.office,
          updatedAt: DateTime.now(),
        ),
        liveLocation: LocationPoint(
          title: "Zara's Cozy Place",
          address: 'Green Hills Sector 2',
          latitude: 28.6050,
          longitude: 77.2120,
          type: LocationType.home,
          updatedAt: DateTime.now(),
        ),
      ),
    ];
  }

  void _populateDefaultInitialChat(UserModel friend, String currentUserId) {
    final encResult1 = _crypto.encryptMessage(
      plainText: 'Hey! Look at my new 3D model with neon streaks! Touch & drag it to orbit 👾✨',
      senderId: friend.id,
      receiverId: currentUserId,
    );

    final msg1 = MessageModel(
      id: _uuid.v4(),
      senderId: friend.id,
      receiverId: currentUserId,
      encryptedPayload: encResult1['cipherText']!,
      iv: encResult1['iv']!,
      decryptedContent: 'Hey! Look at my new 3D model with neon streaks! Touch & drag it to orbit 👾✨',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      isMine: false,
      isRead: true,
      reactionEmoji: '🔥',
    );

    _chatHistory[friend.id] = [msg1];
    _storage.saveMessages(friend.id, [msg1]);
  }

  List<MessageModel> getMessagesForFriend(String friendId) {
    return _chatHistory[friendId] ?? [];
  }

  MessageModel? getLastMessageForFriend(String friendId) {
    final list = _chatHistory[friendId];
    if (list == null || list.isEmpty) return null;
    return list.last;
  }

  Future<void> sendMessage({
    required String currentUserId,
    required String friendId,
    required String text,
    MessageType type = MessageType.text,
    String? avatarReaction,
    String? mediaUrl,
    String? fileName,
    String? fileSize,
    LocationPoint? locationData,
    String? audioDuration,
  }) async {
    if (text.trim().isEmpty && type == MessageType.text) return;

    final contentToEncrypt = text.trim().isNotEmpty ? text.trim() : '[Attachment: ${type.name}]';

    final encryptionResult = _crypto.encryptMessage(
      plainText: contentToEncrypt,
      senderId: currentUserId,
      receiverId: friendId,
    );

    final newMessage = MessageModel(
      id: _uuid.v4(),
      senderId: currentUserId,
      receiverId: friendId,
      encryptedPayload: encryptionResult['cipherText']!,
      iv: encryptionResult['iv']!,
      decryptedContent: contentToEncrypt,
      timestamp: DateTime.now(),
      isMine: true,
      isRead: false,
      type: type,
      avatarReaction: avatarReaction,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      locationData: locationData,
      audioDuration: audioDuration,
    );

    final currentList = _chatHistory[friendId] ?? [];
    currentList.add(newMessage);
    _chatHistory[friendId] = List.from(currentList);

    if (avatarReaction != null) {
      _activeAvatarReactions[currentUserId] = avatarReaction;
    }

    notifyListeners();
    await _storage.saveMessages(friendId, currentList);

    if (type == MessageType.text) {
      _simulateFriendReply(currentUserId, friendId, text.trim());
    } else {
      _simulateAttachmentReply(currentUserId, friendId, type);
    }
  }

  void _simulateAttachmentReply(String currentUserId, String friendId, MessageType type) {
    _typingUsers[friendId] = true;
    notifyListeners();

    Timer(const Duration(milliseconds: 1400), () async {
      _typingUsers[friendId] = false;

      String replyText = "Received your attachment! 🔒 Encrypted & Verified.";
      String reaction = '🔥';

      if (type == MessageType.image) {
        replyText = "Awesome photo! The colors and vibe look amazing 📸✨";
        reaction = '❤️';
      } else if (type == MessageType.video) {
        replyText = "Sick video clip! Playing in high quality 🎥⚡";
        reaction = '🔥';
      } else if (type == MessageType.document) {
        replyText = "Downloaded and verified the file securely 📄✅";
        reaction = '👍';
      } else if (type == MessageType.location) {
        replyText = "Got your location pin on the World Map! Coming over 📍🚀";
        reaction = '📍';
      } else if (type == MessageType.audio) {
        replyText = "Heard your voice note loud & clear! 🎙️🎧";
        reaction = '⚡';
      }

      final encResult = _crypto.encryptMessage(
        plainText: replyText,
        senderId: friendId,
        receiverId: currentUserId,
      );

      final replyMsg = MessageModel(
        id: _uuid.v4(),
        senderId: friendId,
        receiverId: currentUserId,
        encryptedPayload: encResult['cipherText']!,
        iv: encResult['iv']!,
        decryptedContent: replyText,
        timestamp: DateTime.now(),
        isMine: false,
        isRead: true,
        reactionEmoji: reaction,
      );

      final currentList = _chatHistory[friendId] ?? [];
      currentList.add(replyMsg);
      _chatHistory[friendId] = List.from(currentList);
      _activeAvatarReactions[friendId] = reaction;

      notifyListeners();
      await _storage.saveMessages(friendId, currentList);
    });
  }

  void _simulateFriendReply(String currentUserId, String friendId, String userPrompt) {
    _typingUsers[friendId] = true;
    notifyListeners();

    Timer(const Duration(milliseconds: 1400), () async {
      _typingUsers[friendId] = false;

      final friend = _friends.firstWhere((f) => f.id == friendId);
      String replyText = "Yo! Loved your visit on the map! Let's hangout soon 🚀";
      String? reaction = '🔥';

      final lower = userPrompt.toLowerCase();
      if (lower.contains('ghar') || lower.contains('home') || lower.contains('visit')) {
        replyText = "Welcome to my home pin on the map! 🏠 Grab a virtual coffee!";
        reaction = '☕';
      } else if (lower.contains('office') || lower.contains('work')) {
        replyText = "I'm currently at my office pin 💼 Grinding on cool code!";
        reaction = '💻';
      } else if (lower.contains('model') || lower.contains('avatar') || lower.contains('3d')) {
        replyText = "The 3D model looks sick! You can drag and rotate it in 3D perspective 👾✨";
        reaction = '⚡';
      }

      final encResult = _crypto.encryptMessage(
        plainText: replyText,
        senderId: friendId,
        receiverId: currentUserId,
      );

      final replyMsg = MessageModel(
        id: _uuid.v4(),
        senderId: friendId,
        receiverId: currentUserId,
        encryptedPayload: encResult['cipherText']!,
        iv: encResult['iv']!,
        decryptedContent: replyText,
        timestamp: DateTime.now(),
        isMine: false,
        isRead: true,
        reactionEmoji: reaction,
      );

      final currentList = _chatHistory[friendId] ?? [];
      currentList.add(replyMsg);
      _chatHistory[friendId] = List.from(currentList);
      _activeAvatarReactions[friendId] = reaction;

      notifyListeners();
      await _storage.saveMessages(friendId, currentList);
    });
  }

  void addReaction(String friendId, String messageId, String emoji) {
    final list = _chatHistory[friendId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      list[index] = list[index].copyWith(reactionEmoji: emoji);
      notifyListeners();
      _storage.saveMessages(friendId, list);
    }
  }
}
