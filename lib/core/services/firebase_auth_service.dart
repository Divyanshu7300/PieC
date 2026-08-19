import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class FirebaseAuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _firebaseUser;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _verificationId;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _firebaseUser != null && _currentUser != null;
  String? get errorMessage => _errorMessage;

  FirebaseAuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      await _loadUserProfile(user.uid);
    } else {
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc.data()!, uid);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _errorMessage = e.message ?? 'Verification failed';
          _isLoading = false;
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (_verificationId == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final result = await _auth.signInWithCredential(credential);
      _firebaseUser = result.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Invalid OTP';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> saveUserProfile({
    required String name,
    required String phone,
    Map<String, dynamic>? avatarConfig,
  }) async {
    if (_firebaseUser == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final data = {
        'uid': _firebaseUser!.uid,
        'name': name,
        'phone': phone,
        'statusText': 'On PieC',
        'isOnline': true,
        'batteryPercentage': 100,
        'isCharging': false,
        'locationPrivacyMode': 'precise',
        'avatarConfig': avatarConfig ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('users').doc(_firebaseUser!.uid).set(data, SetOptions(merge: true));
      _currentUser = UserModel.fromFirestore(data, _firebaseUser!.uid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> isProfileComplete() async {
    if (_firebaseUser == null) return false;
    final doc = await _firestore.collection('users').doc(_firebaseUser!.uid).get();
    return doc.exists && doc.data()?['name'] != null;
  }

  // Sign in with Email & Password
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _firebaseUser = result.user;
      if (_firebaseUser != null) {
        await _loadUserProfile(_firebaseUser!.uid);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Login failed. Check your email and password.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register with Email & Password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _firebaseUser = result.user;
      if (_firebaseUser != null) {
        await saveUserProfile(
          name: name.trim().isEmpty ? 'PieC User' : name.trim(),
          phone: phone ?? '',
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Registration failed.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateLocation(double lat, double lng) async {
    if (_firebaseUser == null) return;
    await _firestore.collection('users').doc(_firebaseUser!.uid).update({
      'latitude': lat,
      'longitude': lng,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    });
  }

  Future<UserModel?> searchByPhone(String phone) async {
    try {
      final q = await _firestore.collection('users').where('phone', isEqualTo: phone).limit(1).get();
      if (q.docs.isNotEmpty) {
        return UserModel.fromFirestore(q.docs.first.data(), q.docs.first.id);
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }
    return null;
  }
}
