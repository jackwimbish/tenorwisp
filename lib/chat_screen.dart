import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tenorwisp/services/chat_service.dart';
import 'package:tenorwisp/services/storage_service.dart';
import 'package:tenorwisp/chat_bubble.dart';
import 'package:tenorwisp/services/media_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String recipientId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.recipientId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final StorageService _storageService = StorageService();
  final MediaService _mediaService = MediaService();

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _pickMedia() async {
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

    File? compressedFile;
    bool isVideo = false;

    try {
      if (source.contains('video')) {
        isVideo = true;
        compressedFile = await _mediaService.pickAndCompressVideo(
          source: source == 'camera_video'
              ? ImageSource.camera
              : ImageSource.gallery,
          context: context,
        );
      } else {
        compressedFile = await _mediaService.pickAndCompressImage(
          source: source == 'camera_photo'
              ? ImageSource.camera
              : ImageSource.gallery,
        );
      }

      if (compressedFile != null) {
        await _uploadAndSendMedia(compressedFile, isVideo: isVideo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process media: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _uploadAndSendMedia(File file, {required bool isVideo}) async {
    final currentUser = _currentUser;
    if (currentUser == null) return;

    try {
      // 1. Create a placeholder message in Firestore
      final messageRef = await _chatService.createMediaMessagePlaceholder(
        widget.chatId,
      );

      if (isVideo) {
        // 2. Define the upload path for the Cloud Function to catch
        final uploadPath =
            'uploads/${currentUser.uid}/${widget.chatId}/${messageRef.id}.mp4';
        // 3. Upload the file to trigger the cloud function
        await _storageService.uploadFile(file, uploadPath);
      } else {
        // For images, use the existing flow and update the placeholder
        final downloadUrl = await _storageService.uploadChatMedia(
          widget.chatId,
          currentUser.uid,
          file,
        );
        await messageRef.update({
          'imageUrl': downloadUrl,
          'status': 'complete',
        });
      }
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
      return; // Don't send empty messages
    }
    _messageController.clear();
    try {
      await _chatService.sendMessage(widget.chatId, text: messageText);
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
        title: const Text('Chat'), // TODO: Show recipient's name
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                // 1. Handle loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Handle errors
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // 3. Handle no data (although covered by waiting state, good practice)
                if (!snapshot.hasData) {
                  return const Center(child: Text('No messages yet.'));
                }

                final messages = snapshot.data!.docs;

                // 4. Handle empty chat state
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Be the first to say something! 👋'),
                  );
                }

                // 5. Display the list of messages
                return ListView.builder(
                  reverse: true, // Show latest messages at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final message = messageDoc.data() as Map<String, dynamic>;
                    final bool isMe = message['senderId'] == _currentUser?.uid;

                    return ChatBubble(
                      key: ValueKey(messageDoc.id),
                      data: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          // Message input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickMedia,
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
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
