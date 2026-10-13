import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../screens/user_session.dart';
import 'account_policy.dart';
import 'user_data_service.dart';

/// Spark-compatible bookstore membership management. This never changes or
/// deletes Firebase Authentication identities; server rules enforce every write.
class AdminService {
  static final instance = AdminService();
  DatabaseReference get _root => UserDataService.instance.root;

  String _requireAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        !user.emailVerified ||
        user.uid != UserSession.uid ||
        !UserSession.isAdmin) {
      throw StateError('A verified bookstore administrator is required.');
    }
    return user.uid;
  }

  void _requireTarget(String uid) {
    final actor = _requireAdmin();
    if (uid.isEmpty ||
        RegExp(r'[.#$\[\]/]').hasMatch(uid) ||
        uid == actor ||
        uid == bootstrapOwnerUid) {
      throw StateError(
        'Your own account and the bookstore owner are protected.',
      );
    }
  }

  Map<String, bool> _flags(Object? value) {
    final data = value is Map ? value : <String, dynamic>{};
    return {
      'admin': data['admin'] == true,
      'disabled': data['disabled'] == true,
      'removed': data['removed'] == true,
    };
  }

  Future<List<Map<String, dynamic>>> listUsers() async {
    final actor = _requireAdmin();
    final snapshots = await Future.wait([
      _root.child('users').get(),
      _root.child('accountAccess').get(),
    ]);
    final records = snapshots[0].children.map((record) {
      final profile = Map<String, dynamic>.from(record.value as Map);
      final uid = record.key!;
      final flags = _flags(snapshots[1].child(uid).value);
      return <String, dynamic>{
        ...profile,
        'uid': uid,
        'role': uid == bootstrapOwnerUid || flags['admin'] == true
            ? 'Admin'
            : 'Customer',
        'disabled': flags['disabled'],
        'removed': flags['removed'],
        'protected': uid == actor || uid == bootstrapOwnerUid,
      };
    }).toList();
    records.sort(
      (a, b) => a['name'].toString().toLowerCase().compareTo(
        b['name'].toString().toLowerCase(),
      ),
    );
    return records;
  }

  Future<void> _change(
    String uid,
    void Function(Map<String, bool>) mutate,
  ) async {
    _requireTarget(uid);
    final result = await _root.child('accountAccess/$uid').runTransaction((
      current,
    ) {
      final next = _flags(current);
      try {
        mutate(next);
      } catch (_) {
        return Transaction.abort();
      }
      return Transaction.success(next);
    });
    if (!result.committed)
      throw StateError('Access changed. Refresh and try again.');
  }

  Future<void> changeRole(String uid, String role) async {
    if (!['Admin', 'Customer'].contains(role))
      throw ArgumentError('Invalid role.');
    await _change(uid, (flags) {
      if (flags['removed'] == true || flags['disabled'] == true)
        throw StateError(
          'Restore or unblock this account before changing its role.',
        );
      flags['admin'] = role == 'Admin';
    });
  }

  Future<void> setDisabled(String uid, bool disabled) => _change(uid, (flags) {
    if (flags['removed'] == true)
      throw StateError('Restore bookstore access first.');
    flags['disabled'] = disabled;
  });
  Future<void> restoreUser(String uid) => _change(uid, (flags) {
    flags['admin'] = false;
    flags['removed'] = false;
    flags['disabled'] = false;
  });
  Future<void> removeUser(String uid) async {
    _requireTarget(uid);
    // Retain the registration profile for admin listing/restoration and order
    // snapshots for order management. Clear the customer's saved app data.
    await _root.update({
      'accountAccess/$uid': {'admin': false, 'disabled': true, 'removed': true},
      'customerData/$uid': null,
    });
  }
}
