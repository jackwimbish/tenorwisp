import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tenorwisp/chat_screen.dart';
import 'package:tenorwisp/service_locator.dart';
import 'package:tenorwisp/services/user_service.dart';
import 'package:tenorwisp/services/chat_service.dart';
import 'package:tenorwisp/services/auth_service.dart';
import 'package:tenorwisp/create_group_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  _UsersListScreenState createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  late AuthService _authService;
  late ChatService _chatService;
  late UserService _userService;
  Stream<QuerySnapshot>? _chatsStream;

  @override
  void initState() {
    super.initState();
    _authService = getIt<AuthService>();
    _chatService = getIt<ChatService>();
    _userService = getIt<UserService>();
    if (_userService.currentUser != null) {
      _chatsStream = _chatService.getChatsStream(_userService.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("You have no active chats."));
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final chatId = chatDoc.id;

              final isGroupChat = chatData['isGroupChat'] ?? false;

              if (isGroupChat) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(chatData['groupName']?[0] ?? 'G'),
                  ),
                  title: Text(chatData['groupName'] ?? 'Group Chat'),
                  subtitle: Text(chatData['lastMessage'] ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(chatId: chatId),
                      ),
                    );
                  },
                );
              } else {
                return _buildOneToOneChatTile(chatData, chatId);
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          );
        },
        icon: const Icon(Icons.group_add),
        label: const Text('Create New Chat'),
      ),
    );
  }

  Widget _buildOneToOneChatTile(Map<String, dynamic> chatData, String chatId) {
    final List<String> participants = List<String>.from(
      chatData['participants'],
    );
    final otherUserId = participants.firstWhere(
      (id) => id != _userService.currentUser!.uid,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) {
      return const ListTile(title: Text("Error: Could not find other user."));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _userService.getUserDocFuture(otherUserId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const ListTile(title: Text("Loading..."));
        }
        final otherUserData =
            userSnapshot.data?.data() as Map<String, dynamic>?;
        return ListTile(
          leading: CircleAvatar(
            child: Text(otherUserData?['username']?[0] ?? 'U'),
          ),
          title: Text(otherUserData?['username'] ?? 'User'),
          subtitle: Text(chatData['lastMessage'] ?? ''),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChatScreen(chatId: chatId, recipientId: otherUserId),
              ),
            );
          },
        );
      },
    );
  }
}
