import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tenorwisp/services/user_service.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _searchController = TextEditingController();
  final _userService = UserService();
  Future<QuerySnapshot>? _searchResultsFuture;

  Future<void> _sendFriendRequest(String recipientId) async {
    try {
      await _userService.sendFriendRequest(recipientId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: ${e.toString()}')),
        );
      }
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResultsFuture = null;
      });
      return;
    }

    final future = FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: query.trim())
        .get();

    setState(() {
      _searchResultsFuture = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Friend')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search field
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search by email',
                    ),
                    onFieldSubmitted: _performSearch,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _performSearch(_searchController.text),
                  tooltip: 'Search',
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Search results area
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: _searchResultsFuture,
                builder: (context, snapshot) {
                  if (_searchResultsFuture == null) {
                    return const Center(
                      child: Text('Enter an email to search for users.'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No users found with that email.'),
                    );
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final userData = doc.data() as Map<String, dynamic>;
                      final username = userData['username'] ?? 'No username';
                      final recipientId = doc.id;

                      // Don't show the current user in search results
                      if (recipientId ==
                          FirebaseAuth.instance.currentUser?.uid) {
                        return const SizedBox.shrink(); // Return an empty widget
                      }

                      return ListTile(
                        title: Text(username),
                        subtitle: Text(userData['email']),
                        trailing: ElevatedButton(
                          onPressed: () => _sendFriendRequest(recipientId),
                          child: const Text('Add Friend'),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
