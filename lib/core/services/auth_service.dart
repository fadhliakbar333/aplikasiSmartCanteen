import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late SharedPreferences _prefs;
  bool _isAuthenticated = false;
  String? _authToken;
  String? _userRole; // 'user' atau 'admin'
  String? _userId;
  String? _userName;
  String? _userEmail;
  bool _isInitialized = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get authToken => _authToken;
  String? get userRole => _userRole;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _checkAuthStatus();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing AuthService: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _checkAuthStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final loaded = await _loadUserFromFirestore(currentUser.uid);
      _isAuthenticated = loaded;
    } else {
      _isAuthenticated = _prefs.getBool('isAuthenticated') ?? false;
      _authToken = _prefs.getString(AppConstants.keyAuthToken);
      _userRole = _prefs.getString(AppConstants.keyUserRole);
      _userId = _prefs.getString(AppConstants.keyUserId);
      _userName = _prefs.getString(AppConstants.keyUserName);
      _userEmail = _prefs.getString(AppConstants.keyUserEmail);
    }
    notifyListeners();
  }

  Future<bool> _loadUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      _userId = uid;
      _userName = data['name'] as String? ?? '';
      _userEmail = data['email'] as String? ?? _auth.currentUser?.email;
      _userRole = data['role'] as String? ?? 'user';
      _authToken = await _auth.currentUser?.getIdToken();
      _isAuthenticated = true;

      await _saveToPrefs();
      return true;
    } catch (e) {
      debugPrint('Firestore load error: $e');
      return false;
    }
  }

  Future<void> _saveToPrefs() async {
    await _prefs.setBool('isAuthenticated', _isAuthenticated);
    if (_authToken != null) {
      await _prefs.setString(AppConstants.keyAuthToken, _authToken!);
    }
    if (_userRole != null) {
      await _prefs.setString(AppConstants.keyUserRole, _userRole!);
    }
    if (_userId != null) {
      await _prefs.setString(AppConstants.keyUserId, _userId!);
    }
    if (_userName != null) {
      await _prefs.setString(AppConstants.keyUserName, _userName!);
    }
    if (_userEmail != null) {
      await _prefs.setString(AppConstants.keyUserEmail, _userEmail!);
    }
  }

  Future<bool> _login(
    String email,
    String password, {
    required String expectedRole,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) return false;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;

      final data = doc.data();
      final role = data?['role'] as String? ?? 'user';
      if (role != expectedRole) return false;

      _userId = uid;
      _userName = data?['name'] as String? ?? '';
      _userEmail = data?['email'] as String? ?? email;
      _userRole = role;
      _authToken = await credential.user?.getIdToken();
      _isAuthenticated = true;

      await _saveToPrefs();
      notifyListeners();

      // Save FCM token after successful login
      unawaited(NotificationService().saveTokenForUser(uid));

      return true;
    } catch (e) {
      debugPrint('Firebase login error: $e');
      return false;
    }
  }

  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    return _login(email, password, expectedRole: 'user');
  }

  Future<bool> loginAdmin({
    required String email,
    required String password,
  }) async {
    return _login(email, password, expectedRole: 'admin');
  }

  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      // Validate inputs
      if (name.isEmpty) {
        throw Exception('Nama tidak boleh kosong');
      }
      if (email.isEmpty) {
        throw Exception('Email tidak boleh kosong');
      }
      if (password.isEmpty) {
        throw Exception('Password tidak boleh kosong');
      }
      if (password != confirmPassword) {
        throw Exception('Password dan konfirmasi password tidak sesuai');
      }
      if (password.length < 6) {
        throw Exception('Password minimal 6 karakter');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw Exception('Gagal mendapatkan UID user');
      }

      // Create user document in Firestore
      await _firestore.collection('users').doc(uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final loaded = await _loadUserFromFirestore(uid);
      if (!loaded) {
        throw Exception('Gagal memuat data user setelah registrasi');
      }
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Register error: ${e.code} - ${e.message}');
      String message = 'Registrasi gagal';
      if (e.code == 'weak-password') {
        message = 'Password terlalu lemah. Gunakan minimal 6 karakter';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email sudah terdaftar';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      } else if (e.code == 'network-request-failed') {
        message = 'Koneksi internet tidak tersedia';
      } else if (e.message != null) {
        message = e.message!;
      }
      throw Exception(message);
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    // Clear FCM token before logout
    if (_userId != null) {
      unawaited(NotificationService().clearTokenForUser(_userId!));
    }

    await _auth.signOut();
    _isAuthenticated = false;
    _authToken = null;
    _userRole = null;
    _userId = null;
    _userName = null;
    _userEmail = null;

    await _prefs.clear();
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    String? email,
  }) async {
    try {
      if (_userId == null) return;

      final updateData = <String, dynamic>{'name': name};
      if (email != null) {
        updateData['email'] = email;
      }

      await _firestore.collection('users').doc(_userId).update(updateData);
      _userName = name;
      if (email != null) {
        _userEmail = email;
      }

      await _saveToPrefs();
      notifyListeners();
    } catch (e) {
      debugPrint('Update profile error: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Reset Password Error: ${e.code} - ${e.message}');
      String message = 'Gagal mengirim email reset password';
      if (e.code == 'user-not-found') {
        message = 'Email tidak terdaftar';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      } else if (e.code == 'network-request-failed') {
        message = 'Koneksi internet tidak tersedia';
      } else if (e.message != null) {
        message = e.message!;
      }
      throw Exception(message);
    } catch (e) {
      debugPrint('Reset Password Error: $e');
      rethrow;
    }
  }
}
