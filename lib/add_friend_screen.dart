import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isLoading = false;

  Future<void> _sendFriendRequest(String recipientId) async {
    try {
      await _userService.sendFriendRequest(recipientId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
        // Refresh search to update button state
        _performSearch(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: ${e.toString()}')),
        );
      }
    }
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final results = await _userService.searchUsers(query.trim());

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
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
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search by username or email',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _performSearch(_searchController.text),
                  tooltip: 'Search',
                ),
              ),
              onSubmitted: _performSearch,
            ),
            const SizedBox(height: 20),
            // Search results area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.trim().isEmpty) {
      return const Center(child: Text('Enter a username or email to search.'));
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    // Use a StreamBuilder to get the current user's friends and requests
    return StreamBuilder<DocumentSnapshot>(
      stream: _userService.getUserDocStream(_userService.currentUser!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final currentUserData = snapshot.data!.data() as Map<String, dynamic>;
        final friends =
            (currentUserData['friends'] as List?)?.cast<String>() ?? [];
        final sentRequests =
            (currentUserData['friendRequestsSent'] as List?)?.cast<String>() ??
            [];

        final filteredResults = _searchResults
            .where((doc) => doc.id != _userService.currentUser!.uid)
            .toList();

        if (filteredResults.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        return ListView.builder(
          itemCount: filteredResults.length,
          itemBuilder: (context, index) {
            final userDoc = filteredResults[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            final username = userData['username'] ?? 'No username';
            final email = userData['email'] ?? 'No email';
            final recipientId = userDoc.id;

            Widget trailingButton;
            if (friends.contains(recipientId)) {
              trailingButton = const ElevatedButton(
                onPressed: null,
                child: Text('Friends'),
              );
            } else if (sentRequests.contains(recipientId)) {
              trailingButton = const ElevatedButton(
                onPressed: null,
                child: Text('Request Sent'),
              );
            } else {
              trailingButton = ElevatedButton(
                onPressed: () => _sendFriendRequest(recipientId),
                child: const Text('Add Friend'),
              );
            }

            return ListTile(
              title: Text(username),
              subtitle: Text(email),
              trailing: trailingButton,
            );
          },
        );
      },
    );
  }
}
