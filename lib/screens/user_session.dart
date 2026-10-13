import 'package:flutter/material.dart';
import '../models/book.dart';

class UserSession {
  static String uid = '';
  static String name = '';
  static String email = '';
  static String phone = '';
  static String role = 'Customer';
  static bool bootstrapAdmin = false;
  static bool isLoggedIn = false;
  static bool get isAdmin => role == 'Admin';
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static final ValueNotifier<int> profileChanges = ValueNotifier<int>(0);
  static final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);
  static List<Map<String, String>> users = [];
  static List<Map<String, String>> shippingAddresses = [];
  static List<Map<String, String>> paymentMethods = [];
  static Map<String, String> orderReadStatus = {};
  static bool pushNotifications = true;
  static bool emailOffers = true;

  static void setCurrentUser(Map<String, dynamic> data) {
    shippingAddresses = [];
    paymentMethods = [];
    orderReadStatus = {};
    pushNotifications = true;
    emailOffers = true;
    users = [];
    ReviewStore.clear();
    darkMode.value = false;
    uid = (data['uid'] ?? '').toString();
    name = (data['name'] ?? '').toString();
    email = (data['email'] ?? '').toString();
    phone = (data['phone'] ?? '').toString();
    role = (data['role'] ?? 'Customer').toString();
    bootstrapAdmin = data['bootstrapAdmin'] == true;
    isLoggedIn = uid.isNotEmpty;
    changes.value++;
  }

  static void setUsersFromRecords(List<Map<String, dynamic>> records) {
    users = records
        .map(
          (r) => {
            'uid': (r['uid'] ?? '').toString(),
            'name': (r['name'] ?? '').toString(),
            'email': (r['email'] ?? '').toString(),
            'phone': (r['phone'] ?? '').toString(),
            'role': (r['role'] ?? 'Customer').toString(),
          },
        )
        .toList();
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
    bootstrapAdmin = false;
    isLoggedIn = false;
    users = [];
    shippingAddresses = [];
    paymentMethods = [];
    orderReadStatus = {};
    pushNotifications = true;
    emailOffers = true;
    ReviewStore.clear();
    darkMode.value = false;
    changes.value++;
  }

  static void setDarkMode(bool value) {
    darkMode.value = value;
  }
}
