import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../screens/user_session.dart';
import 'auth_service.dart';

class UserDataService extends ChangeNotifier {
  UserDataService._();
  static final instance = UserDataService._();
  final List<StreamSubscription<DatabaseEvent>> _subscriptions = [];
  int _generation = 0;
  String? error;
  bool loading = false;
  DatabaseReference get root => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: AuthService.databaseUrl,
  ).ref();
  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != UserSession.uid || !user.emailVerified) {
      throw StateError('Please sign in with a verified account.');
    }
    return user.uid;
  }

  Future<void> bind(String uid) async {
    final generation = ++_generation;
    final previous = List<StreamSubscription<DatabaseEvent>>.from(
      _subscriptions,
    );
    _subscriptions.clear();
    error = null;
    loading = uid.isNotEmpty;
    notifyListeners();
    await Future.wait(previous.map((s) => s.cancel()));
    if (generation != _generation || uid.isEmpty) return;
    var profileReady = false, dataReady = false;
    void failed(Object _) {
      if (generation != _generation) return;
      error = 'Profile data could not be loaded. Please retry.';
      loading = false;
      notifyListeners();
    }

    _subscriptions.add(
      root.child('users/$uid').onValue.listen((event) {
        if (generation != _generation) return;
        final data = event.snapshot.value;
        if (data is Map) {
          UserSession.name = (data['name'] ?? UserSession.name).toString();
          UserSession.phone = (data['phone'] ?? '').toString();
        }
        profileReady = true;
        loading = !profileReady || !dataReady;
        UserSession.profileChanges.value++;
        notifyListeners();
      }, onError: failed),
    );
    _subscriptions.add(
      root.child('customerData/$uid').onValue.listen((event) {
        if (generation != _generation) return;
        UserSession.shippingAddresses = _records(
          event.snapshot.child('addresses'),
        );
        UserSession.paymentMethods = _records(
          event.snapshot.child('paymentMethods'),
        );
        UserSession.orderReadStatus = {
          for (final order in event.snapshot.child('orderReadStatus').children)
            order.key!: order.value.toString(),
        };
        final preferences = event.snapshot.child('preferences');
        UserSession.pushNotifications =
            preferences.child('pushNotifications').value != false;
        UserSession.emailOffers =
            preferences.child('emailOffers').value != false;
        UserSession.darkMode.value =
            preferences.child('darkMode').value == true;
        dataReady = true;
        loading = !profileReady || !dataReady;
        UserSession.profileChanges.value++;
        notifyListeners();
      }, onError: failed),
    );
  }

  List<Map<String, String>> _records(DataSnapshot snapshot) => snapshot.children
      .map(
        (child) => {
          'id': child.key!,
          for (final entry in (child.value as Map).entries)
            entry.key.toString(): entry.value.toString(),
        },
      )
      .toList();

  Future<void> saveProfile(String name, String phone) async {
    final uid = _uid;
    if (name.trim().length < 2 || name.trim().length > 120)
      throw ArgumentError('Use a name between 2 and 120 characters.');
    if (phone.trim().length > 30)
      throw ArgumentError('Phone number is too long.');
    await root.child('users/$uid').update({
      'name': name.trim(),
      'phone': phone.trim(),
    });
    // Database profile is authoritative for the app; displayName is only a fallback.
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.uid == uid) await user?.updateDisplayName(name.trim());
    } catch (_) {}
  }

  Future<void> requestEmailChange(String email, String password) async {
    final uid = _uid;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim()))
      throw ArgumentError('Enter a valid email.');
    final user = FirebaseAuth.instance.currentUser!;
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: password),
    );
    if (FirebaseAuth.instance.currentUser?.uid != uid)
      throw StateError('Account changed. Sign in again.');
    await user.verifyBeforeUpdateEmail(email.trim());
  }

  Future<void> saveAddress(Map<String, String> value, {String? id}) async {
    final uid = _uid;
    const keys = ['name', 'phone', 'address', 'area', 'city'];
    final data = {for (final key in keys) key: (value[key] ?? '').trim()};
    if (data.values.any((v) => v.isEmpty))
      throw ArgumentError('Fill in every address field.');
    if (data['phone']!.replaceAll(RegExp(r'\D'), '').length < 10)
      throw ArgumentError('Enter a valid phone number.');
    final ref = root.child('customerData/$uid/addresses');
    await (id == null ? ref.push() : ref.child(id)).set(data);
  }

  Future<void> deleteAddress(String id) =>
      root.child('customerData/$_uid/addresses/$id').remove();

  Future<void> savePaymentMetadata(
    String brand,
    String last4,
    String expiry,
  ) async {
    final uid = _uid;
    if (!['Visa', 'Mastercard', 'American Express'].contains(brand) ||
        !RegExp(r'^\d{4}$').hasMatch(last4) ||
        !RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(expiry)) {
      throw ArgumentError(
        'Select a brand, exactly four ending digits and MM/YY expiry.',
      );
    }
    final parts = expiry.split('/');
    final end = DateTime(2000 + int.parse(parts[1]), int.parse(parts[0]) + 1);
    if (!end.isAfter(DateTime.now()))
      throw ArgumentError('This card has expired.');
    // No PAN, CVV or cardholder details are collected/stored here.
    await root.child('customerData/$uid/paymentMethods').push().set({
      'brand': brand,
      'last4': last4,
      'expiry': expiry,
    });
  }

  Future<void> deletePaymentMetadata(String id) =>
      root.child('customerData/$_uid/paymentMethods/$id').remove();
  Future<void> markOrderRead(String orderId, String status) =>
      root.child('customerData/$_uid/orderReadStatus/$orderId').set(status);
  Future<void> savePreference(String key, bool value) {
    if (!['darkMode', 'pushNotifications', 'emailOffers'].contains(key))
      throw ArgumentError('Unknown preference.');
    return root.child('customerData/$_uid/preferences/$key').set(value);
  }
}
