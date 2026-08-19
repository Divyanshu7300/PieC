import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:piec/core/crypto/e2ee_engine.dart';
import 'package:piec/core/models/avatar_config.dart';
import 'package:piec/core/models/friend_request_model.dart';
import 'package:piec/core/models/location_point.dart';
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
    _loadSampleDiscoverableUsers();
    _loadSampleNearbyRadarUsers();

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyPendingRequests);
    if (data != null && data.isNotEmpty) {
      try {
        final List decoded = jsonDecode(data);
        _pendingRequests =
            decoded.map((item) => FriendRequestModel.fromMap(item)).toList();
      } catch (_) {
        _populateDefaultInitialRequests(currentUserId);
      }
    } else {
      _populateDefaultInitialRequests(currentUserId);
    }
    notifyListeners();
  }

  void _populateDefaultInitialRequests(String currentUserId) {
    _pendingRequests = [
      FriendRequestModel(
        id: 'req_knock_maya',
        sender: UserModel(
          id: 'user_maya',
          name: 'Maya Lin',
          username: 'maya_cyber',
          statusText: 'Knocking at your Home Base 🏠',
          isOnline: true,
          publicKey: _crypto.generatePublicKey('user_maya'),
          lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
          avatarConfig: const AvatarConfig(
            hairStyle: HairStyle.longFlowyWavy,
            hairBaseColorHex: 0xFF1C1427,
            hairHighlightColorHex: 0xFFFF2A85,
            irisColor: IrisColor.rubyRed,
            outfitStyle: OutfitStyle.cyberHoodieWithGlow,
            outfitPrimaryColorHex: 0xFFFF2A85,
            outfitSecondaryColorHex: 0xFF00F0FF,
            accessory: AvatarAccessory.studioHeadphonesLed,
            auraEffect: AvatarAuraEffect.none,
            pose: AvatarPose.wavingHand,
            glowColorHex: 0xFFFF2A85,
          ),
          homeLocation: LocationPoint(
            title: "Maya's Studio",
            address: 'Art District Tower 3',
            latitude: 28.6195,
            longitude: 77.2060,
            type: LocationType.home,
            updatedAt: DateTime.now(),
          ),
          liveLocation: LocationPoint(
            title: "Your Home Gate",
            address: 'Waiting outside',
            latitude: 28.6150,
            longitude: 77.2099,
            type: LocationType.live,
            updatedAt: DateTime.now(),
          ),
        ),
        receiverId: currentUserId,
        type: FriendRequestType.knockKnockMap,
        placeTitle: 'My Home Base 🏠',
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      FriendRequestModel(
        id: 'req_radar_kabir',
        sender: UserModel(
          id: 'user_kabir',
          name: 'Kabir Verma',
          username: 'kabir_drift',
          statusText: '18m away at Cyber Cafe ☕',
          isOnline: true,
          publicKey: _crypto.generatePublicKey('user_kabir'),
          lastActive: DateTime.now().subtract(const Duration(minutes: 2)),
          avatarConfig: const AvatarConfig(
            hairStyle: HairStyle.pompadourVolume,
            hairBaseColorHex: 0xFF2D1E12,
            hairHighlightColorHex: 0xFFFFD600,
            irisColor: IrisColor.amberGold,
            facialHair: FacialHair.stubbleShadow,
            outfitStyle: OutfitStyle.bomberJacketLeather,
            outfitPrimaryColorHex: 0xFFFF6B00,
            outfitSecondaryColorHex: 0xFFFFD600,
            accessory: AvatarAccessory.retroAviatorGlasses,
            auraEffect: AvatarAuraEffect.fireFlameEnergy,
            pose: AvatarPose.peaceSign,
            glowColorHex: 0xFFFF6B00,
          ),
          liveLocation: LocationPoint(
            title: 'Central Cafe Lounge',
            address: 'Table 4 (18m away)',
            latitude: 28.6142,
            longitude: 77.2093,
            type: LocationType.hangout,
            updatedAt: DateTime.now(),
          ),
        ),
        receiverId: currentUserId,
        type: FriendRequestType.nearbyRadar,
        placeTitle: 'Nearby Radar Bump 📡',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];
    _save();
  }

  void _loadSampleDiscoverableUsers() {
    _discoverableUsers = [
      UserModel(
        id: 'user_rohit',
        name: 'Rohit Deshmukh',
        username: 'rohit_matrix',
        phone: '9876543210',
        statusText: 'Exploring 3D Spatial Maps 🚀',
        isOnline: true,
        publicKey: _crypto.generatePublicKey('user_rohit'),
        lastActive: DateTime.now(),
        avatarConfig: const AvatarConfig(
          hairStyle: HairStyle.animeSpiky,
          hairBaseColorHex: 0xFF1C1427,
          hairHighlightColorHex: 0xFF00FF9D,
          irisColor: IrisColor.neonEmerald,
          facialHair: FacialHair.cyberGoatee,
          outfitStyle: OutfitStyle.neonTechArmor,
          outfitPrimaryColorHex: 0xFF00FF9D,
          outfitSecondaryColorHex: 0xFF00F0FF,
          accessory: AvatarAccessory.cyberVisorHolo,
          auraEffect: AvatarAuraEffect.cyberSparks,
          glowColorHex: 0xFF00FF9D,
        ),
      ),
      UserModel(
        id: 'user_tanya',
        name: 'Tanya Sharma',
        username: 'tanya_pixel',
        phone: '9812345678',
        statusText: 'Listening to Lo-Fi beats 🎧',
        isOnline: true,
        publicKey: _crypto.generatePublicKey('user_tanya'),
        lastActive: DateTime.now(),
        avatarConfig: const AvatarConfig(
          hairStyle: HairStyle.kpopCurtains,
          hairBaseColorHex: 0xFF2D1E12,
          hairHighlightColorHex: 0xFFB026FF,
          irisColor: IrisColor.electricPurple,
          outfitStyle: OutfitStyle.cozyOversizedSweater,
          outfitPrimaryColorHex: 0xFF8B5CF6,
          outfitSecondaryColorHex: 0xFFFF2A85,
          accessory: AvatarAccessory.royalCyberCrown,
          auraEffect: AvatarAuraEffect.none,
          glowColorHex: 0xFFB026FF,
        ),
      ),
      UserModel(
        id: 'user_aarav',
        name: 'Aarav Mehta',
        username: 'aarav_cyber',
        phone: '9988776655',
        statusText: 'Gaming with squad 🎮',
        isOnline: true,
        publicKey: _crypto.generatePublicKey('user_aarav'),
        lastActive: DateTime.now(),
        avatarConfig: const AvatarConfig(
          hairStyle: HairStyle.pompadourVolume,
          hairBaseColorHex: 0xFF1C1427,
          hairHighlightColorHex: 0xFFFFD600,
          irisColor: IrisColor.amberGold,
          facialHair: FacialHair.stubbleShadow,
          outfitStyle: OutfitStyle.bomberJacketLeather,
          outfitPrimaryColorHex: 0xFFFF6B00,
          outfitSecondaryColorHex: 0xFFFFD600,
          accessory: AvatarAccessory.studioHeadphonesLed,
          auraEffect: AvatarAuraEffect.fireFlameEnergy,
          glowColorHex: 0xFFFF6B00,
        ),
      ),
    ];
  }

  void _loadSampleNearbyRadarUsers() {
    _nearbyRadarUsers = [
      UserModel(
        id: 'radar_neha',
        name: 'Neha Kapoor',
        username: 'neha_space',
        statusText: '12m away • At Cafe Bar',
        isOnline: true,
        publicKey: _crypto.generatePublicKey('radar_neha'),
        lastActive: DateTime.now(),
        avatarConfig: const AvatarConfig(
          hairStyle: HairStyle.cyberPunkFade,
          hairBaseColorHex: 0xFF1C1427,
          hairHighlightColorHex: 0xFF00F0FF,
          irisColor: IrisColor.cyberCyan,
          outfitStyle: OutfitStyle.cyberHoodieWithGlow,
          outfitPrimaryColorHex: 0xFF00F0FF,
          outfitSecondaryColorHex: 0xFFB026FF,
          accessory: AvatarAccessory.studioHeadphonesLed,
          auraEffect: AvatarAuraEffect.cyberSparks,
          pose: AvatarPose.wavingHand,
          glowColorHex: 0xFF00F0FF,
        ),
      ),
      UserModel(
        id: 'radar_dev',
        name: 'Dev Singhania',
        username: 'dev_gamer',
        statusText: '35m away • In Transit 🚗',
        isOnline: true,
        publicKey: _crypto.generatePublicKey('radar_dev'),
        lastActive: DateTime.now(),
        avatarConfig: const AvatarConfig(
          hairStyle: HairStyle.undercutSlick,
          hairBaseColorHex: 0xFF2D1E12,
          hairHighlightColorHex: 0xFFFFD600,
          irisColor: IrisColor.amberGold,
          facialHair: FacialHair.stubbleShadow,
          outfitStyle: OutfitStyle.bomberJacketLeather,
          outfitPrimaryColorHex: 0xFFFF6B00,
          outfitSecondaryColorHex: 0xFFFFD600,
          accessory: AvatarAccessory.goldCyberChain,
          auraEffect: AvatarAuraEffect.fireFlameEnergy,
          glowColorHex: 0xFFFF6B00,
        ),
      ),
    ];
  }

  List<UserModel> searchUsers(String query) {
    if (query.trim().isEmpty) return _discoverableUsers;
    final lower = query.toLowerCase().trim();
    final cleanDigits = query.replaceAll(RegExp(r'[^0-9]'), '');

    return _discoverableUsers.where((u) {
      final nameMatches = u.name.toLowerCase().contains(lower);
      final usernameMatches = u.username.toLowerCase().contains(lower);
      final phoneMatches = cleanDigits.isNotEmpty &&
          (u.phone?.replaceAll(RegExp(r'[^0-9]'), '').contains(cleanDigits) ?? false);

      return nameMatches || usernameMatches || phoneMatches;
    }).toList();
  }

  Future<void> sendFriendRequest({
    required UserModel sender,
    required UserModel receiver,
    required FriendRequestType type,
    String? placeTitle,
  }) async {
    final request = FriendRequestModel(
      id: _uuid.v4(),
      sender: sender,
      receiverId: receiver.id,
      type: type,
      placeTitle: placeTitle,
      timestamp: DateTime.now(),
    );

    // In local demo, add to pending list
    _pendingRequests.insert(0, request);
    notifyListeners();
    await _save();
  }

  Future<UserModel?> acceptFriendRequest(
    String requestId, {
    FriendPrivacyAccess access = FriendPrivacyAccess.fullMapAccess,
  }) async {
    final index = _pendingRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return null;

    final acceptedRequest = _pendingRequests[index];
    _pendingRequests.removeAt(index);
    notifyListeners();
    await _save();

    return acceptedRequest.sender;
  }

  Future<void> declineFriendRequest(String requestId) async {
    _pendingRequests.removeWhere((r) => r.id == requestId);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _pendingRequests.map((r) => r.toMap()).toList();
    await prefs.setString(_keyPendingRequests, jsonEncode(list));
  }
}
