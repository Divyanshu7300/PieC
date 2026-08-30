import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:piec/core/crypto/e2ee_engine.dart';
import 'package:piec/core/models/avatar_config.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/storage_service.dart';

class AuthService extends ChangeNotifier {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  final StorageService _storage = StorageService();
  final E2EEEngine _crypto = E2EEEngine();

  AuthService() {
    _firebaseAuth.authStateChanges().listen((user) async {
      if (user == null) {
        _currentUser = null;
      } else {
        final profile = await _db.collection('users').doc(user.uid).get();
        _currentUser = profile.exists && profile.data() != null
            ? UserModel.fromFirestore(profile.data()!, user.uid)
            : null;
      }
      notifyListeners();
    });
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // Firebase Auth is the only identity source allowed to use cloud data.
    // Local storage remains a cache and is never synced as a separate identity.
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final profile = await _db.collection('users').doc(user.uid).get();
      _currentUser = profile.exists && profile.data() != null
          ? UserModel.fromFirestore(profile.data()!, user.uid)
          : null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _syncToFirestore(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).set(
        user.toFirestore(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Sync user to Firestore error: $e');
    }
  }

  /// Sends OTP to phone number (simulated / real-ready)
  Future<bool> sendOtp(String phoneNumber) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Verifies OTP and logs in or creates new user
  Future<bool> verifyOtp(String phoneNumber, String enteredOtp) async {
    if (enteredOtp != '123456' && enteredOtp.length != 6) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    final userId = 'user_${phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')}';
    final user = UserModel(
      id: userId,
      name: 'Agent ${phoneNumber.substring(phoneNumber.length > 4 ? phoneNumber.length - 4 : 0)}',
      username: 'user_${phoneNumber.substring(phoneNumber.length > 4 ? phoneNumber.length - 4 : 0)}',
      phone: phoneNumber,
      publicKey: _crypto.generatePublicKey(userId),
      lastActive: DateTime.now(),
      homeLocation: LocationPoint(
        title: 'My Home Base',
        address: 'Sector 4, Central Area',
        latitude: 28.6150,
        longitude: 77.2099,
        type: LocationType.home,
        updatedAt: DateTime.now(),
      ),
      officeLocation: LocationPoint(
        title: 'Cyber Workspace',
        address: 'Tech Innovation Park',
        latitude: 28.6200,
        longitude: 77.2150,
        type: LocationType.office,
        updatedAt: DateTime.now(),
      ),
      liveLocation: LocationPoint(
        title: 'Current Spot',
        address: 'Downtown Hub',
        latitude: 28.6139,
        longitude: 77.2090,
        type: LocationType.live,
        updatedAt: DateTime.now(),
      ),
    );

    _currentUser = user;
    await _storage.saveCurrentUser(user);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Sign In with Google
  Future<bool> signInWithGoogle({
    String email = 'gamer.cyber@gmail.com',
    String name = 'Cyber Knight',
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));
    final userId = 'user_${email.split('@').first}';
    final user = UserModel(
      id: userId,
      name: name,
      username: email.split('@').first,
      email: email,
      publicKey: _crypto.generatePublicKey(userId),
      lastActive: DateTime.now(),
      avatarConfig: const AvatarConfig(
        hairStyle: HairStyle.cyberPunkFade,
        hairBaseColorHex: 0xFF1C1427,
        hairHighlightColorHex: 0xFF00F0FF,
        irisColor: IrisColor.cyberCyan,
        facialHair: FacialHair.stubbleShadow,
        outfitStyle: OutfitStyle.cyberHoodieWithGlow,
        outfitPrimaryColorHex: 0xFF8B5CF6,
        outfitSecondaryColorHex: 0xFF00F0FF,
        accessory: AvatarAccessory.studioHeadphonesLed,
        auraEffect: AvatarAuraEffect.none,
        glowColorHex: 0xFF00F0FF,
      ),
      homeLocation: LocationPoint(
        title: 'My Home Base',
        address: 'Palm Grove Residency',
        latitude: 28.6150,
        longitude: 77.2099,
        type: LocationType.home,
        updatedAt: DateTime.now(),
      ),
      officeLocation: LocationPoint(
        title: 'Design Studio',
        address: 'Cyber City Hub',
        latitude: 28.6220,
        longitude: 77.2180,
        type: LocationType.office,
        updatedAt: DateTime.now(),
      ),
      liveLocation: LocationPoint(
        title: 'Live Location',
        address: 'City Center Plaza',
        latitude: 28.6139,
        longitude: 77.2090,
        type: LocationType.live,
        updatedAt: DateTime.now(),
      ),
    );

    _currentUser = user;
    await _storage.saveCurrentUser(user);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Update Username & Name
  Future<void> updateProfile({required String name, required String username}) async {
    if (_currentUser == null) return;
    final normalizedUsername = username.trim().toLowerCase().replaceFirst('@', '');
    if (!RegExp(r'^[a-z0-9_.]{3,30}$').hasMatch(normalizedUsername)) {
      throw ArgumentError('Username must be 3–30 characters: letters, numbers, _ or .');
    }
    _currentUser = _currentUser!.copyWith(
      name: name.trim(),
      username: normalizedUsername,
    );
    if (_firebaseAuth.currentUser?.uid == _currentUser!.id) {
      await _db.collection('users').doc(_currentUser!.id).set({
        'uid': _currentUser!.id,
        'name': _currentUser!.name,
        'username': normalizedUsername,
        'usernameLower': normalizedUsername,
        'avatarConfig': _currentUser!.avatarConfig.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await _storage.saveCurrentUser(_currentUser!);
    notifyListeners();
  }

  /// Update Avatar
  Future<void> updateAvatarConfig(AvatarConfig config) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(avatarConfig: config);
    if (_firebaseAuth.currentUser?.uid == _currentUser!.id) {
      await _db.collection('users').doc(_currentUser!.id).update({
        'avatarConfig': config.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await _storage.saveCurrentUser(_currentUser!);
    notifyListeners();
  }

  /// Set Home / Office location tag
  Future<void> setLocationTag({
    LocationPoint? home,
    LocationPoint? office,
    LocationPoint? live,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      homeLocation: home ?? _currentUser!.homeLocation,
      officeLocation: office ?? _currentUser!.officeLocation,
      liveLocation: live ?? _currentUser!.liveLocation,
    );
    if (_firebaseAuth.currentUser?.uid == _currentUser!.id) {
      await _db.collection('users').doc(_currentUser!.id).set({
        if (home != null) 'homeLocation': home.toMap(),
        if (office != null) 'officeLocation': office.toMap(),
        if (live != null) 'liveLocation': live.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await _storage.saveCurrentUser(_currentUser!);
    notifyListeners();
  }

  /// Toggle Ghost Mode
  Future<void> toggleGhostMode(bool enabled) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      isGhostMode: enabled,
      privacyMode: enabled ? LocationPrivacyMode.ghost : _currentUser!.privacyMode,
    );
    if (_firebaseAuth.currentUser?.uid == _currentUser!.id) {
      await _db.collection('users').doc(_currentUser!.id).update({
        'isGhostMode': enabled,
        'locationPrivacyMode': _currentUser!.privacyMode.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await _storage.saveCurrentUser(_currentUser!);
    await _storage.setGhostMode(enabled);
    notifyListeners();
  }

  /// Update Location Privacy Mode (Precise, Blurred, Ghost)
  Future<void> updatePrivacyMode(LocationPrivacyMode mode) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      privacyMode: mode,
      isGhostMode: mode == LocationPrivacyMode.ghost,
    );
    if (_firebaseAuth.currentUser?.uid == _currentUser!.id) {
      await _db.collection('users').doc(_currentUser!.id).update({
        'isGhostMode': mode == LocationPrivacyMode.ghost,
        'locationPrivacyMode': mode.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await _storage.saveCurrentUser(_currentUser!);
    await _storage.setGhostMode(mode == LocationPrivacyMode.ghost);
    notifyListeners();
  }

  /// Update Battery Level & Charging State
  Future<void> updateBattery(int level, bool isCharging) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      batteryPercentage: level,
      isCharging: isCharging,
    );
    await _storage.saveCurrentUser(_currentUser!);
    notifyListeners();
  }

  /// Update Status
  Future<void> updateStatus(String statusText) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(statusText: statusText);
    if (_firebaseAuth.currentUser?.uid == _currentUser!.id) {
      await _db.collection('users').doc(_currentUser!.id).update({
        'statusText': statusText.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await _storage.saveCurrentUser(_currentUser!);
    notifyListeners();
  }

  /// Save and set current active user
  Future<void> saveCurrentUser(UserModel user) async {
    _currentUser = user;
    await _storage.saveCurrentUser(user);
    await _syncToFirestore(user);
    notifyListeners();
  }

  /// Logout
  Future<void> logout() async {
    _currentUser = null;
    await _storage.clearUser();
    notifyListeners();
  }
}
