import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  // This function handles finding or creating a chat and then navigating.
  Future<void> _navigateToChat(
    String recipientId,
    String recipientUsername,
  ) async {
    final currentUserUid = _currentUser?.uid;
    if (currentUserUid == null) return;

    // A consistent way to generate a chat ID between two users
    final participants = [currentUserUid, recipientId]..sort();
    final chatId = participants.join('_');

    // Check if a chat document with this ID already exists
    final chatDocRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId);
    final chatDoc = await chatDocRef.get();

    if (!chatDoc.exists) {
      // If chat doesn't exist, create it
      await chatDocRef.set({
        'participants': participants,
        'lastMessage': 'Chat started',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: chatId, recipientId: recipientId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Message')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final friends =
              (userData['friends'] as List<dynamic>?)?.cast<String>() ?? [];

          if (friends.isEmpty) {
            return const Center(
              child: Text('You have no friends to message. Add some!'),
            );
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friendId = friends[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text('Loading...'));
                  }
                  final friendData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final username = friendData['username'] ?? 'No Username';

                  return ListTile(
                    title: Text(username),
                    onTap: () => _navigateToChat(friendId, username),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
