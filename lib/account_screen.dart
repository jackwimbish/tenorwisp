import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'friends_screen.dart';
import 'package:tenorwisp/services/auth_service.dart';
import 'package:tenorwisp/services/user_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final _usernameController = TextEditingController();
  final _authService = AuthService();
  final _userService = UserService();
  bool _isUploading = false;
  bool _isSavingUsername = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _updateUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      return;
    }

    setState(() {
      _isSavingUsername = true;
    });

    try {
      await _userService.updateUsername(newUsername);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully!')),
        );
        _usernameController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update username: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingUsername = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(pickedFile.path);
      await _userService.updateProfilePicture(file);
      // The StreamBuilder in the main app shell will update the UI.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _authService.signOut();
      // The AuthWrapper will automatically navigate to the LoginScreen.
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: ListView(
        children: [
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Friends'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const FriendsScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit Profile is not yet implemented.'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Change Password is not yet implemented.'),
                ),
              );
            },
          ),
          const Divider(height: 40),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Logout',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
