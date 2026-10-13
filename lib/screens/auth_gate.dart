import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'user_session.dart';

/// Startup gate: decides whether to show the login screen or jump straight
/// into the app based on the persisted Firebase session.
///
/// A user who logged in previously (and verified their email) is sent to the
/// main shell without having to sign in again. Anyone else lands on login.
/// The static admin is intentionally not auto-logged-in (it isn't a Firebase
/// account), so admins sign in each session.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _decideStartRoute();
  }

  Future<void> _decideStartRoute() async {
    String target = '/login';

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      final fresh = FirebaseAuth.instance.currentUser;

      if (fresh != null && fresh.emailVerified) {
        // Load the profile from the Realtime Database; fall back to the
        // Firebase user fields if the record can't be read.
        Map<String, dynamic> data;
        try {
          data = await AuthService.instance.fetchUser(fresh.uid) ??
              _fallback(fresh);
        } catch (_) {
          data = _fallback(fresh);
        }
        UserSession.setCurrentUser(data);
        target = '/main_shell';
      } else {
        // Signed in but not verified — don't let them in.
        await FirebaseAuth.instance.signOut();
      }
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, target);
  }

  Map<String, dynamic> _fallback(User user) => {
    'uid': user.uid,
    'name': user.displayName ?? '',
    'email': user.email ?? '',
    'phone': '',
    'role': 'Customer',
  };

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1E4D3B);
    const cream = Color(0xFFF5F5F0);

    return const Scaffold(
      backgroundColor: cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, color: green, size: 56),
            SizedBox(height: 20),
            CircularProgressIndicator(color: green),
          ],
        ),
      ),
    );
  }
}
