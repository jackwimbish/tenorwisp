import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tenorwisp/services/user_service.dart';
import 'add_friend_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Friends'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
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

            return TabBarView(
              children: [
                _buildUserList(friendIds),
                _buildRequestList(requestIds),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AddFriendScreen()));
          },
          child: const Icon(Icons.person_add),
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
