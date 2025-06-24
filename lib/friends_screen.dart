import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_friend_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _acceptFriendRequest(String requesterId) async {
    final currentUserUid = _currentUser?.uid;
    if (currentUserUid == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Current user's document:
      // 1. Remove from 'friendRequestsReceived'
      // 2. Add to 'friends'
      final currentUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid);
      batch.update(currentUserRef, {
        'friendRequestsReceived': FieldValue.arrayRemove([requesterId]),
        'friends': FieldValue.arrayUnion([requesterId]),
      });

      // Requester's document:
      // 1. Remove from 'friendRequestsSent'
      // 2. Add to 'friends'
      final requesterRef = FirebaseFirestore.instance
          .collection('users')
          .doc(requesterId);
      batch.update(requesterRef, {
        'friendRequestsSent': FieldValue.arrayRemove([currentUserUid]),
        'friends': FieldValue.arrayUnion([currentUserUid]),
      });

      await batch.commit();

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
    final currentUserUid = _currentUser?.uid;
    if (currentUserUid == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Current user's document: Remove from 'friendRequestsReceived'
      final currentUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid);
      batch.update(currentUserRef, {
        'friendRequestsReceived': FieldValue.arrayRemove([requesterId]),
      });

      // Requester's document: Remove from 'friendRequestsSent'
      final requesterRef = FirebaseFirestore.instance
          .collection('users')
          .doc(requesterId);
      batch.update(requesterRef, {
        'friendRequestsSent': FieldValue.arrayRemove([currentUserUid]),
      });

      await batch.commit();
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
              .doc(_currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Could not load user data.'));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final friendRequests =
                (userData['friendRequestsReceived'] as List<dynamic>?)
                    ?.cast<String>() ??
                [];
            final friends =
                (userData['friends'] as List<dynamic>?)?.cast<String>() ?? [];

            return TabBarView(
              children: [
                // My Friends List
                if (friends.isEmpty)
                  const Center(child: Text('You have no friends yet. Add one!'))
                else
                  ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friendId = friends[index];
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(friendId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const ListTile(title: Text('Loading...'));
                          }
                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return ListTile(title: Text('Unknown User'));
                          }

                          final friendData =
                              userSnapshot.data!.data() as Map<String, dynamic>;
                          final username =
                              friendData['username'] ?? 'No Username';

                          return ListTile(
                            title: Text(username),
                            subtitle: Text(friendData['email']),
                          );
                        },
                      );
                    },
                  ),

                // Friend Requests List
                if (friendRequests.isEmpty)
                  const Center(
                    child: Text('You have no pending friend requests.'),
                  )
                else
                  ListView.builder(
                    itemCount: friendRequests.length,
                    itemBuilder: (context, index) {
                      final userId = friendRequests[index];
                      // We need another StreamBuilder to get the user's details
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return const ListTile(title: Text('Loading...'));
                          }
                          final requestUserData =
                              userSnapshot.data!.data() as Map<String, dynamic>;
                          final username =
                              requestUserData['username'] ?? 'No Username';

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
                                  onPressed: () =>
                                      _declineFriendRequest(userId),
                                  child: const Text('Decline'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
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
}
