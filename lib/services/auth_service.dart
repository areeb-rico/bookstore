import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'account_policy.dart';

/// Thrown by [AuthService] with a user-friendly [message] that the UI can
/// show directly in a SnackBar.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Handles all authentication + user-record work against Firebase
/// Authentication and the Realtime Database.
///
/// User records are stored at `/users/{uid}` so the whole app (and the admin
/// panel) can fetch a user and their details by uid.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ---------------------------------------------------------------------------
  // Realtime Database URL.
  //
  // This is filled in once you create the Realtime Database in the Firebase
  // Console. If you pick the default "United States (us-central1)" location the
  // URL below is correct. If you pick another region, replace it with the URL
  // shown at the top of the Realtime Database page, e.g.
  //   https://bookstore-fe6f2-default-rtdb.europe-west1.firebasedatabase.app
  // ---------------------------------------------------------------------------
  static const String databaseUrl =
      'https://bookstore-fe6f2-default-rtdb.firebaseio.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  DatabaseReference get _rootRef => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseUrl,
  ).ref();
  DatabaseReference get _usersRef => _rootRef.child('users');

  User? get currentUser => _auth.currentUser;

  Stream<Map<String, dynamic>> watchAccess(String uid) => _rootRef
      .child('accountAccess/$uid')
      .onValue
      .map(
        (event) => event.snapshot.value is Map
            ? Map<String, dynamic>.from(event.snapshot.value as Map)
            : <String, dynamic>{},
      );

  /// Spark roles are protected database records; the bootstrap owner's claim
  /// remains the trusted starting point. Editable profile roles grant no access.
  Future<Map<String, dynamic>> loadSession(User user) async {
    final token = await user.getIdTokenResult(true);
    final accessSnapshot = await _rootRef
        .child('accountAccess/${user.uid}')
        .get();
    final access = accessSnapshot.value is Map
        ? Map<String, dynamic>.from(accessSnapshot.value as Map)
        : <String, dynamic>{};
    if (access['disabled'] == true || access['removed'] == true) {
      await _auth.signOut();
      throw const AuthException(
        'Your bookstore access is blocked or removed. Contact the administrator.',
      );
    }
    final ownerAdmin =
        user.uid == bootstrapOwnerUid && token.claims?['admin'] == true;
    final profile = await fetchUser(user.uid) ?? <String, dynamic>{};
    if (profile.isEmpty) {
      profile.addAll({
        'uid': user.uid,
        'name': (user.displayName?.trim().length ?? 0) >= 2
            ? user.displayName!.trim()
            : 'Reader',
        'email': user.email ?? '',
        'phone': '',
        'role': 'Customer',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });
      await _usersRef.child(user.uid).set(profile);
    }
    // Refresh the profile email after a verified Firebase email change.
    if (profile.isNotEmpty && profile['email'] != user.email) {
      await _usersRef.child(user.uid).child('email').set(user.email);
    }
    return {
      ...profile,
      'uid': user.uid,
      'name': profile['name'] ?? user.displayName ?? '',
      'email': user.email ?? '',
      'phone': profile['phone'] ?? '',
      'role': ownerAdmin || access['admin'] == true ? 'Admin' : 'Customer',
      'bootstrapAdmin': ownerAdmin,
    };
  }

  // ---------------------------------------------------------------------------
  // REGISTER
  // ---------------------------------------------------------------------------
  /// Creates the auth account, stores the profile in the Realtime Database,
  /// sends a verification email, then signs the user back out so they must
  /// verify before they can log in.
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      await user.updateDisplayName(name);

      // Store the user record in the Realtime Database.
      await _usersRef.child(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': user.email ?? email,
        'phone': phone,
        'role': 'Customer',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Send the verification email, then sign out until they verify.
      await user.sendEmailVerification();
      await _auth.signOut();
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } on FirebaseException catch (e) {
      throw AuthException(
        'Could not save your profile: ${e.message ?? e.code}',
      );
    } catch (_) {
      throw const AuthException('Something went wrong. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------
  /// Signs in, enforces email verification, and returns the user's record from
  /// the Realtime Database. Throws [AuthException] with a friendly message on
  /// any failure (including an unverified email).
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      await user.reload();

      if (!_auth.currentUser!.emailVerified) {
        await _auth.signOut();
        throw const AuthException(
          'Please verify your email first. Check your inbox for the '
          'verification link.',
        );
      }

      return await loadSession(_auth.currentUser!);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } on FirebaseException catch (e) {
      throw AuthException(
        'Signed in, but could not load your data: ${e.message ?? e.code}',
      );
    } catch (_) {
      throw const AuthException('Something went wrong. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // RESEND VERIFICATION EMAIL
  // ---------------------------------------------------------------------------
  /// Signs in temporarily to resend the verification email, then signs out.
  Future<void> resendVerification({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      if (user.emailVerified) {
        await _auth.signOut();
        throw const AuthException(
          'This email is already verified. Please log in.',
        );
      }
      await user.sendEmailVerification();
      await _auth.signOut();
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } catch (_) {
      throw const AuthException('Could not resend the email. Try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // PASSWORD RESET
  // ---------------------------------------------------------------------------
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } catch (_) {
      throw const AuthException('Could not send the reset email. Try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // FETCH USERS
  // ---------------------------------------------------------------------------
  /// Reads a single user record from `/users/{uid}`.
  Future<Map<String, dynamic>?> fetchUser(String uid) async {
    final snapshot = await _usersRef.child(uid).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  /// Reads every user record (used by the admin panel).
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final snapshot = await _usersRef.get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final raw = Map<String, dynamic>.from(snapshot.value as Map);
    return raw.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ---------------------------------------------------------------------------
  // SIGN OUT
  // ---------------------------------------------------------------------------
  Future<void> signOut() => _auth.signOut();

  // ---------------------------------------------------------------------------
  // Error mapping
  // ---------------------------------------------------------------------------
  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'weak-password':
        return 'Password is too weak (use at least 6 characters).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
