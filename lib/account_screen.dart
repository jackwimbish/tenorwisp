import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final _usernameController = TextEditingController();
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
      final usernameDoc = await FirebaseFirestore.instance.collection('usernames').doc(newUsername).get();

      if (usernameDoc.exists) {
        throw Exception('Username is already taken.');
      }

      final userDoc = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
      final oldUserData = (await userDoc.get()).data();
      final oldUsername = oldUserData?['username'];

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Update username in user's document
      batch.set(userDoc, {'username': newUsername}, SetOptions(merge: true));

      // Create new username document
      batch.set(FirebaseFirestore.instance.collection('usernames').doc(newUsername), {'uid': _user!.uid});

      // Delete old username document if it exists
      if (oldUsername != null) {
        batch.delete(FirebaseFirestore.instance.collection('usernames').doc(oldUsername));
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully!')),
        );
        _usernameController.clear();
      }

    } catch (e) {
      if(mounted) {
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
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${_user!.uid}.jpg');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await _user!.updatePhotoURL(url);
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set(
        {'photoURL': url},
        SetOptions(merge: true),
      );

      // No need to call setState here as the StreamBuilder will handle it
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      if(mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(_user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }

          final userData = snapshot.data?.data();
          final username = userData?['username'] as String?;
          final photoURL = userData?['photoURL'] as String?;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          backgroundImage: (photoURL != null && !photoURL.contains('dicebear.com'))
                            ? NetworkImage(photoURL)
                            : null,
                          child: (photoURL != null && photoURL.contains('dicebear.com'))
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: SvgPicture.network(
                                  photoURL,
                                  fit: BoxFit.cover,
                                  placeholderBuilder: (context) => const CircularProgressIndicator(),
                                ),
                              )
                            : (photoURL == null ? const Icon(Icons.person, size: 60) : null),
                        ),
                        if (_isUploading)
                          const CircularProgressIndicator()
                        else
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: _pickAndUploadImage,
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      username ?? _user?.email ?? 'No email available',
                      style: theme.textTheme.headlineSmall,
                    ),
                    if (username == null)
                      Text(
                        _user?.email ?? '',
                        style: theme.textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 32),
                    
                    // Username form
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Set new username',
                        hintText: 'Enter a unique username',
                        suffixIcon: _isSavingUsername
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: _updateUsername,
                            ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Log Out'),
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 