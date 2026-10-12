import 'package:flutter/material.dart';

class UserSession {
  static String name = '';
  static String email = '';
  static String phone = '';

  static String registeredName = '';
  static String registeredEmail = '';
  static String registeredPhone = '';
  static String registeredPassword = '';

  static bool isLoggedIn = false;

  // REGISTERED USERS (mock, shared with the admin panel)
  static List<Map<String, String>> users = [
    {
      'name': 'Admin',
      'email': 'admin@gmail.com',
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

  static bool register({
    required String userName,
    required String userEmail,
    required String userPhone,
    required String userPassword,
  }) {
    registeredName = userName;
    registeredEmail = userEmail;
    registeredPhone = userPhone;
    registeredPassword = userPassword;

    name = userName;
    email = userEmail;
    phone = userPhone;
    isLoggedIn = true;

    users.add({
      'name': userName,
      'email': userEmail,
      'phone': userPhone,
      'role': 'Customer',
    });

    return true;
  }

  static bool login({required String userEmail, required String userPassword}) {
    if (registeredEmail.isEmpty || registeredPassword.isEmpty) {
      return false;
    }

    if (userEmail.trim().toLowerCase() ==
            registeredEmail.trim().toLowerCase() &&
        userPassword == registeredPassword) {
      name = registeredName;
      email = registeredEmail;
      phone = registeredPhone;
      isLoggedIn = true;

      return true;
    }

    return false;
  }

  // Mock password reset: updates the stored password for the account.
  static bool resetPassword({
    required String userEmail,
    required String newPassword,
  }) {
    if (registeredEmail.isEmpty) {
      return false;
    }

    if (userEmail.trim().toLowerCase() !=
        registeredEmail.trim().toLowerCase()) {
      return false;
    }

    registeredPassword = newPassword;
    return true;
  }

  static void updateProfile({
    required String userName,
    required String userEmail,
    required String userPhone,
  }) {
    name = userName;
    email = userEmail;
    phone = userPhone;

    registeredName = userName;
    registeredEmail = userEmail;
    registeredPhone = userPhone;
  }

  static void logout() {
    name = '';
    email = '';
    phone = '';
    isLoggedIn = false;
  }

  static void setDarkMode(bool value) {
    darkMode.value = value;
  }

  static bool hasAccount() {
    return registeredEmail.isNotEmpty && registeredPassword.isNotEmpty;
  }
}
