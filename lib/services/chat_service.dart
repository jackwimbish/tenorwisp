import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tenorwisp/service_locator.dart';
import 'package:tenorwisp/services/media_service.dart';
import 'package:tenorwisp/services/storage_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // This function handles finding or creating a chat and returns the chat ID.
  Future<String> getOrCreateChat(String otherUserId) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in.');
    }

    // Create a consistent chatId regardless of who starts the chat
    List<String> ids = [currentUser.uid, otherUserId];
    ids.sort();
    String chatId = ids.join('_');

    // Check if the chat document already exists
    final chatDocRef = _firestore.collection('chats').doc(chatId);
    final docSnapshot = await chatDocRef.get();

    // If it doesn't exist, create it
    if (!docSnapshot.exists) {
      await chatDocRef.set({
        'participants': ids,
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  // Use a transaction to send a message and update the parent chat doc
  Future<void> sendMessage(
    String chatId, {
    String? text,
    String? senderUsername,
  }) async {
    final currentUser = _firebaseAuth.currentUser!;
    final message = {
      'senderId': currentUser.uid,
      'senderUsername': senderUsername,
      'timestamp': FieldValue.serverTimestamp(),
      'viewed': false,
      'expiresAt': null,
      'text': text,
      'imageUrl': null,
      'videoUrl': null,
      'thumbnailUrl': null,
      'aspectRatio': null,
      'status': 'complete',
    };

    final chatDocRef = _firestore.collection('chats').doc(chatId);
    final messageDocRef = chatDocRef.collection('messages').doc();

    return _firestore.runTransaction((transaction) async {
      // Get the chat document
      final chatSnapshot = await transaction.get(chatDocRef);
      if (!chatSnapshot.exists) {
        throw Exception("Chat does not exist!");
      }

      // Add participants to the message for security rules
      final participants =
          (chatSnapshot.data()!['participants'] as List<dynamic>)
              .cast<String>();
      final messageWithParticipants = {
        ...message,
        'participants': participants,
      };

      // Set the new message
      transaction.set(messageDocRef, messageWithParticipants);

      // Update the last message on the parent chat document
      transaction.update(chatDocRef, {
        'lastMessage': text,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  // This is now just for creating the placeholder for media uploads
  Future<DocumentReference> _createMediaMessagePlaceholder(
    String chatId,
  ) async {
    final currentUser = _firebaseAuth.currentUser!;
    final chatDocRef = _firestore.collection('chats').doc(chatId);

    // We need to get the participants to embed them in the message doc
    final chatSnapshot = await chatDocRef.get();
    if (!chatSnapshot.exists) {
      throw Exception("Cannot create message in a chat that does not exist.");
    }
    final participants = (chatSnapshot.data()!['participants'] as List<dynamic>)
        .cast<String>();

    final message = {
      'senderId': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'viewed': false,
      'expiresAt': null,
      'text': null,
      'imageUrl': null,
      'videoUrl': null,
      'thumbnailUrl': null,
      'aspectRatio': null,
      'status': 'uploading',
      'participants': participants, // Embed participants for security rules
    };
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message);
  }

  Future<void> sendMediaMessage({
    required String chatId,
    required String source,
    required BuildContext context,
  }) async {
    final mediaService = getIt<MediaService>();
    final storageService = getIt<StorageService>();
    final currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) return;

    final isVideo = source.contains('video');
    final imageSource = source == 'camera_photo' || source == 'camera_video'
        ? ImageSource.camera
        : ImageSource.gallery;

    File? compressedFile;
    if (isVideo) {
      compressedFile = await mediaService.pickAndCompressVideo(
        source: imageSource,
        context: context,
      );
    } else {
      compressedFile = await mediaService.pickAndCompressImage(
        source: imageSource,
      );
    }

    if (compressedFile == null) return;

    final messageRef = await _createMediaMessagePlaceholder(chatId);

    if (isVideo) {
      final uploadPath =
          'uploads/${currentUser.uid}/$chatId/${messageRef.id}.mp4';
      await storageService.uploadFile(compressedFile, uploadPath);
    } else {
      final downloadUrl = await storageService.uploadChatMedia(
        chatId,
        currentUser.uid,
        compressedFile,
      );
      await messageRef.update({'imageUrl': downloadUrl, 'status': 'complete'});
    }
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      // Return an empty stream if the user is not logged in.
      return const Stream.empty();
    }
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        // Add this clause to match our security rules.
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  Future<void> createChatWith(String otherUserId) async {
    // ... existing code ...
  }

  Future<String> createGroupChat(
    String groupName,
    List<String> friendIds,
  ) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in.');
    }

    // Add the current user to the list of participants
    final participants = [currentUser.uid, ...friendIds];

    // Create a new chat document with a unique ID
    final chatDocRef = _firestore.collection('chats').doc();

    await chatDocRef.set({
      'participants': participants,
      'isGroupChat': true,
      'groupName': groupName,
      'createdBy': currentUser.uid,
      'lastMessage': 'Group created',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });

    return chatDocRef.id;
  }
}
