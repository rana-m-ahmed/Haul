import 'package:flutter/material.dart';
import '../../shared/widgets/haul_empty_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: const HaulEmptyState(
        title: 'Hello, User',
        message: 'Manage your orders, settings, and more.',
        icon: Icons.person_outline,
      ),
    );
  }
}
