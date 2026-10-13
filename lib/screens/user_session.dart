import 'package:flutter/material.dart';

class UserSession {
  // ---------------------------------------------------------------------------
  // ADMIN (static credentials — not a Firebase account).
  // Logging in with these on the normal login screen opens the admin panel.
  // ---------------------------------------------------------------------------
  static const String adminEmail = 'admin@bookstore.com';
  static const String adminPassword = 'admin@123';

  static bool isAdminCredentials(String email, String password) {
    return email.trim().toLowerCase() == adminEmail &&
        password == adminPassword;
  }

  // Current signed-in user
  static String uid = '';
  static String name = '';
  static String email = '';
  static String phone = '';
  static String role = 'Customer';

  static bool isLoggedIn = false;
  static bool get isAdmin => role == 'Admin';

  // REGISTERED USERS (populated from the Realtime Database for the admin panel)
  static List<Map<String, String>> users = [
    {
      'name': 'Admin',
      'email': adminEmail,
      'phone': '',
      'role': 'Admin',
    },
  ];

  // SAVED SHIPPING ADDRESSES (mock, shared across the app)
  static List<Map<String, String>> shippingAddresses = [
    {
      "name": "Muhammad Asim",
      "phone": "03001234567",
      "address": "House 12, Street 4",
      "area": "Gulshan-e-Iqbal",
      "city": "Karachi",
    },
  ];

  // DARK MODE
  static final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);

  /// Populates the current-user fields from a Realtime Database user record.
  static void setCurrentUser(Map<String, dynamic> data) {
    uid = (data['uid'] ?? '').toString();
    name = (data['name'] ?? '').toString();
    email = (data['email'] ?? '').toString();
    phone = (data['phone'] ?? '').toString();
    role = (data['role'] ?? 'Customer').toString();
    isLoggedIn = true;
  }

  /// Marks the session as the static admin account.
  static void setAdminSession() {
    uid = 'admin';
    name = 'Admin';
    email = adminEmail;
    phone = '';
    role = 'Admin';
    isLoggedIn = true;
  }

  /// Replaces the admin-panel user list with records fetched from the
  /// Realtime Database.
  static void setUsersFromRecords(List<Map<String, dynamic>> records) {
    users = [
      {
        'name': 'Admin',
        'email': adminEmail,
        'phone': '',
        'role': 'Admin',
      },
      ...records.map(
        (r) => {
          'name': (r['name'] ?? '').toString(),
          'email': (r['email'] ?? '').toString(),
          'phone': (r['phone'] ?? '').toString(),
          'role': (r['role'] ?? 'Customer').toString(),
        },
      ),
    ];
  }

  static void updateProfile({
    required String userName,
    required String userEmail,
    required String userPhone,
  }) {
    name = userName;
    email = userEmail;
    phone = userPhone;
  }

  static void logout() {
    uid = '';
    name = '';
    email = '';
    phone = '';
    role = 'Customer';
    isLoggedIn = false;
  }

  static void setDarkMode(bool value) {
    darkMode.value = value;
  }
}
