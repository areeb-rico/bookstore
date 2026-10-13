import 'package:flutter/material.dart';
import '../profile.dart';

/// Retained route wrapper; profile editing uses the persistent shared screen.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const ProfileScreen(orders: []);
}
