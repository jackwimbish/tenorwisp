import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // This function handles finding or creating a chat and returns the chat ID.
  Future<String> getOrCreateChat(String recipientId) async {
    final currentUserUid = _firebaseAuth.currentUser?.uid;
    if (currentUserUid == null) throw Exception("User not logged in");

    // A consistent way to generate a chat ID between two users
    final participants = [currentUserUid, recipientId]..sort();
    final chatId = participants.join('_');

    // Check if a chat document with this ID already exists
    final chatDocRef = _firestore.collection('chats').doc(chatId);
    final chatDoc = await chatDocRef.get();

    if (!chatDoc.exists) {
      // If chat doesn't exist, create it
      await chatDocRef.set({
        'participants': participants,
        'lastMessage': 'Chat started',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  Future<void> sendMessage(
    String chatId, {
    String? text,
    String? imageUrl,
    String? videoUrl,
  }) async {
    final currentUserUid = _firebaseAuth.currentUser?.uid;
    if (currentUserUid == null) throw Exception("User not logged in");

    if (text?.isEmpty ?? true && imageUrl == null && videoUrl == null) {
      return; // Don't send empty messages
    }

    final message = {
      'senderId': currentUserUid,
      'text': text,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final chatRef = _firestore.collection('chats').doc(chatId);

    // Add the message to the messages subcollection
    await chatRef.collection('messages').add(message);

    // Also, update the lastMessage field on the main chat document
    String lastMessage;
    if (imageUrl != null) {
      lastMessage = '📷 Image';
    } else if (videoUrl != null) {
      lastMessage = '📹 Video';
    } else {
      lastMessage = text!;
    }

    await chatRef.update({
      'lastMessage': lastMessage,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });
  }
}
