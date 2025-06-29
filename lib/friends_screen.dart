import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tenorwisp/services/user_service.dart';
import 'add_friend_screen.dart';

class FriendsScreen extends StatefulWidget {
  final int initialTabIndex;

  const FriendsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _userService = UserService();

  Future<void> _acceptFriendRequest(String requesterId) async {
    try {
      await _userService.acceptFriendRequest(requesterId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept request: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _declineFriendRequest(String requesterId) async {
    try {
      await _userService.declineFriendRequest(requesterId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline request: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeFriend(String friendId) async {
    // Capture the ScaffoldMessenger before the async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show a confirmation dialog before removing the friend
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Unfriend?'),
          content: const Text('Are you sure you want to remove this friend?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Unfriend'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog
                try {
                  await _userService.removeFriend(friendId);
                  // Use the captured ScaffoldMessenger
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Friend removed.')),
                  );
                } catch (e) {
                  // Use the captured ScaffoldMessenger
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove friend: ${e.toString()}'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: widget.initialTabIndex,
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Friends')),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_userService.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Could not load user data.'));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final friendIds =
                (userData['friends'] as List<dynamic>?)?.cast<String>() ?? [];
            final requestIds =
                (userData['friendRequestsReceived'] as List<dynamic>?)
                    ?.cast<String>() ??
                [];

            final theme = Theme.of(context);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add a Friend'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddFriendScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
                TabBar(
                  tabs: [
                    const Tab(text: 'My Friends'),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Requests'),
                          if (requestIds.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(
                                  requestIds.length.toString(),
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildUserList(friendIds),
                      _buildRequestList(requestIds),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserList(List<String> userIds) {
    if (userIds.isEmpty) {
      return const Center(child: Text('You have no friends yet. Add one!'));
    }
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: _userService.getUsersStream(userIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            final username = userData['username'] ?? 'No Username';
            return ListTile(
              title: Text(username),
              subtitle: Text(userData['email']),
              trailing: IconButton(
                icon: const Icon(Icons.person_remove_outlined),
                onPressed: () => _removeFriend(userDoc.id),
                tooltip: 'Unfriend',
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestList(List<String> userIds) {
    if (userIds.isEmpty) {
      return const Center(child: Text('You have no pending friend requests.'));
    }
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: _userService.getUsersStream(userIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            final username = userData['username'] ?? 'No Username';
            final userId = userDoc.id;

            return ListTile(
              title: Text(username),
              subtitle: Text('Wants to be your friend.'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _acceptFriendRequest(userId),
                    child: const Text('Accept'),
                  ),
                  TextButton(
                    onPressed: () => _declineFriendRequest(userId),
                    child: const Text('Decline'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
