import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:tenorwisp/chat_bubble.dart';

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
  final _messageController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;

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

    final picker = ImagePicker();
    XFile? pickedFile;

    try {
      if (source == 'gallery_photo') {
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
      } else if (source == 'camera_photo') {
        pickedFile = await picker.pickImage(source: ImageSource.camera);
      } else if (source == 'camera_video') {
        pickedFile = await picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(seconds: 60),
        );
      }

      if (pickedFile != null) {
        await _uploadMedia(pickedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick media: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _uploadMedia(XFile file) async {
    final isVideo = file.path.toLowerCase().endsWith('.mp4');
    final fileToUpload = File(file.path);
    final fileExtension = isVideo ? 'mp4' : 'jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final destination =
        'chat_media/${widget.chatId}/${_currentUser?.uid}/$fileName';

    try {
      final ref = FirebaseStorage.instance.ref(destination);
      await ref.putFile(fileToUpload);
      final downloadUrl = await ref.getDownloadURL();
      if (isVideo) {
        await _sendMessage(videoUrl: downloadUrl);
      } else {
        await _sendMessage(imageUrl: downloadUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload media: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _sendMessage({String? imageUrl, String? videoUrl}) async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty && imageUrl == null && videoUrl == null) {
      return; // Don't send empty messages
    }
    _messageController.clear();

    final message = {
      'senderId': _currentUser?.uid,
      'text': imageUrl == null ? messageText : null,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Add the message to the messages subcollection
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add(message);

    // Also, update the lastMessage field on the main chat document
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
          'lastMessage': imageUrl != null
              ? '📷 Image'
              : videoUrl != null
              ? '📹 Video'
              : messageText,
          'lastMessage': imageUrl != null ? '📷 Image' : messageText,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });
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
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true, // Show latest messages at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final message = messageDoc.data() as Map<String, dynamic>;
                    final bool isMe = message['senderId'] == _currentUser?.uid;

                    return ChatBubble(
                      key: ValueKey(
                        messageDoc.id,
                      ), // Use message ID as a unique key
                      text: message['text'],
                      imageUrl: message['imageUrl'],
                      videoUrl: message['videoUrl'],
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
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
