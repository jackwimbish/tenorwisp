import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tenorwisp/services/chat_service.dart';
import 'package:tenorwisp/services/user_service.dart';
import 'chat_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _userService = UserService();
  final _chatService = ChatService();

  Future<void> _navigateToChat(String recipientId) async {
    try {
      final chatId = await _chatService.getOrCreateChat(recipientId);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ChatScreen(chatId: chatId, recipientId: recipientId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open chat: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Message')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_userService.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final friendIds =
              (userData['friends'] as List<dynamic>?)?.cast<String>() ?? [];

          if (friendIds.isEmpty) {
            return const Center(
              child: Text('You have no friends to message. Add some!'),
            );
          }

          return StreamBuilder<List<DocumentSnapshot>>(
            stream: _userService.getUsersStream(friendIds),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final friends = snapshot.data!;
              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friendDoc = friends[index];
                  final friendData = friendDoc.data() as Map<String, dynamic>;
                  final username = friendData['username'] ?? 'No Username';
                  final friendId = friendDoc.id;

                  return ListTile(
                    title: Text(username),
                    onTap: () => _navigateToChat(friendId),
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
