import 'package:flutter/material.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Message')),
      body: const Center(child: Text('User list will be displayed here.')),
    );
  }
}
