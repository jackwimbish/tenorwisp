import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tenorwisp/service_locator.dart';
import 'package:tenorwisp/services/chat_service.dart';
import 'package:tenorwisp/services/media_service.dart';
import 'package:tenorwisp/chat_bubble.dart';
import 'package:tenorwisp/services/user_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String? recipientId;

  const ChatScreen({super.key, required this.chatId, this.recipientId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = getIt<ChatService>();
  final MediaService _mediaService = getIt<MediaService>();
  final UserService _userService = getIt<UserService>();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  Map<String, String> _participantsUsernames = {};
  bool _isGroupChat = false;

  @override
  void initState() {
    super.initState();
    _fetchChatInfo();
  }

  Future<void> _fetchChatInfo() async {
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();

    if (chatDoc.exists) {
      final chatData = chatDoc.data() as Map<String, dynamic>;
      final isGroup = chatData['isGroupChat'] ?? false;
      setState(() {
        _isGroupChat = isGroup;
      });

      if (isGroup) {
        final List<String> participantIds = List<String>.from(
          chatData['participants'],
        );
        final users = await _userService.getUsersStream(participantIds).first;
        final Map<String, String> usernames = {
          for (var user in users)
            user.id:
                (user.data() as Map<String, dynamic>)['username'] as String? ??
                'User',
        };
        setState(() {
          _participantsUsernames = usernames;
        });
      }
    }
  }

  Future<void> _pickAndSendMedia() async {
    final mediaService = getIt<MediaService>();
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose Photo'),
              onTap: () => Navigator.of(context).pop('gallery_photo'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(context).pop('camera_photo'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () => Navigator.of(context).pop('camera_video'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      await _chatService.sendMediaMessage(
        chatId: widget.chatId,
        source: source,
        context: context,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send media: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) {
      return;
    }
    _messageController.clear();
    try {
      await _chatService.sendMessage(
        widget.chatId,
        text: messageText,
        senderUsername: _currentUser?.displayName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .snapshots(),
          builder: (context, chatSnapshot) {
            if (!chatSnapshot.hasData) {
              return const Text('Loading...');
            }
            final chatData = chatSnapshot.data!.data() as Map<String, dynamic>;
            final isGroupChat = chatData['isGroupChat'] ?? false;

            if (isGroupChat) {
              return Text(chatData['groupName'] ?? 'Group Chat');
            } else {
              // For 1-on-1 chats, we need to fetch the other user's name
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.recipientId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Text('Loading...');
                  }
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  return Text(userData['username'] ?? 'Chat');
                },
              );
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Be the first to say something! 👋'));
        }

        final messages = snapshot.data!.docs;
        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageDoc = messages[index];
            final message = messageDoc.data() as Map<String, dynamic>;
            final bool isMe = message['senderId'] == _currentUser?.uid;

            // For group chats, add the sender's username to the data map
            if (_isGroupChat && !isMe) {
              final senderId = message['senderId'];
              message['senderUsername'] =
                  _participantsUsernames[senderId] ?? 'User';
            }

            return ChatBubble(
              key: ValueKey(messageDoc.id),
              data: message,
              isMe: isMe,
              isGroupChat: _isGroupChat,
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _pickAndSendMedia,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
          ],
        ),
      ),
    );
  }
}
