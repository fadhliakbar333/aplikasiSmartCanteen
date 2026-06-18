import 'package:flutter/material.dart';

class AppConstants {
  // API
  static const String baseUrl = 'https://api.smartcanteen.com/api';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';

  // Pagination
  static const int defaultPageSize = 20;

  // Validation
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 20;

  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusProcessing = 'processing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusCompleted = 'completed';
  static const String orderStatusCancelled = 'cancelled';

  // Payment Methods
  static const List<String> paymentMethods = [
    'QRIS',
    'E-Wallet',
    'Tunai',
  ];

  // Colors
  static const Color primaryColor = Color(0xFF7C3AED);
  static const Color secondaryColor = Color(0xFFFF8C42);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFFB923C);
  static const Color infoColor = Color(0xFF3B82F6);
}

class AppStrings {
  // Errors
  static const String errorEmptyField = 'Field tidak boleh kosong';
  static const String errorInvalidEmail = 'Email tidak valid';
  static const String errorPasswordMismatch = 'Password tidak sesuai';
  static const String errorNetworkError = 'Terjadi kesalahan jaringan';
  static const String errorServerError = 'Terjadi kesalahan server';
  static const String errorUnknown = 'Terjadi kesalahan';

  // Success
  static const String successLogin = 'Login berhasil';
  static const String successRegister = 'Registrasi berhasil';
  static const String successLogout = 'Logout berhasil';
  static const String successAddToCart = 'Ditambahkan ke keranjang';
  static const String successOrder = 'Pesanan berhasil dibuat';

  // Common
  static const String appName = 'SmartCanteen';
  static const String appVersion = '1.0.0';
  static const String welcome = 'Selamat Datang';
  static const String login = 'Masuk';
  static const String register = 'Daftar';
  static const String logout = 'Keluar';
  static const String cancel = 'Batal';
  static const String ok = 'OK';
  static const String delete = 'Hapus';
  static const String edit = 'Edit';
  static const String save = 'Simpan';
  static const String loading = 'Memuat...';
  static const String noData = 'Tidak ada data';
}
