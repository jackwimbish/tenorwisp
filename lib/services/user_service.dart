import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> updateUsername(String newUsername) async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    if (newUsername.trim().isEmpty) {
      throw Exception("Username cannot be empty");
    }

    final usernameDoc = await _firestore
        .collection('usernames')
        .doc(newUsername)
        .get();
    if (usernameDoc.exists) {
      throw Exception('Username is already taken.');
    }

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final oldUserData = (await userDocRef.get()).data();
    final oldUsername = oldUserData?['username'];

    WriteBatch batch = _firestore.batch();

    batch.update(userDocRef, {'username': newUsername});
    batch.set(_firestore.collection('usernames').doc(newUsername), {
      'uid': user.uid,
    });

    if (oldUsername != null) {
      batch.delete(_firestore.collection('usernames').doc(oldUsername));
    }
    await user.updateDisplayName(newUsername);
    await batch.commit();
  }

  Future<String> updateProfilePicture(File file) async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    final ref = _storage
        .ref()
        .child('profile_pictures')
        .child('${user.uid}.jpg');

    final uploadTask = await ref.putFile(file);
    final url = await uploadTask.ref.getDownloadURL();

    await user.updatePhotoURL(url);
    await _firestore.collection('users').doc(user.uid).update({
      'photoURL': url,
    });

    return url;
  }

  Stream<DocumentSnapshot> getUserDocStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  Stream<List<DocumentSnapshot>> getUsersStream(List<String> userIds) {
    if (userIds.isEmpty) return Stream.value([]);
    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: userIds)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> sendFriendRequest(String recipientId) async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    final batch = _firestore.batch();
    final currentUserRef = _firestore.collection('users').doc(user.uid);
    batch.update(currentUserRef, {
      'friendRequestsSent': FieldValue.arrayUnion([recipientId]),
    });
    final recipientUserRef = _firestore.collection('users').doc(recipientId);
    batch.update(recipientUserRef, {
      'friendRequestsReceived': FieldValue.arrayUnion([user.uid]),
    });
    await batch.commit();
  }

  Future<void> acceptFriendRequest(String requesterId) async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    final batch = _firestore.batch();
    final currentUserRef = _firestore.collection('users').doc(user.uid);
    batch.update(currentUserRef, {
      'friendRequestsReceived': FieldValue.arrayRemove([requesterId]),
      'friends': FieldValue.arrayUnion([requesterId]),
    });
    final requesterRef = _firestore.collection('users').doc(requesterId);
    batch.update(requesterRef, {
      'friendRequestsSent': FieldValue.arrayRemove([user.uid]),
      'friends': FieldValue.arrayUnion([user.uid]),
    });
    await batch.commit();
  }

  Future<void> declineFriendRequest(String requesterId) async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    final batch = _firestore.batch();
    final currentUserRef = _firestore.collection('users').doc(user.uid);
    batch.update(currentUserRef, {
      'friendRequestsReceived': FieldValue.arrayRemove([requesterId]),
    });
    final requesterRef = _firestore.collection('users').doc(requesterId);
    batch.update(requesterRef, {
      'friendRequestsSent': FieldValue.arrayRemove([user.uid]),
    });
    await batch.commit();
  }

  Future<void> removeFriend(String friendId) async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    final batch = _firestore.batch();

    // Remove friend from current user's list
    final currentUserRef = _firestore.collection('users').doc(user.uid);
    batch.update(currentUserRef, {
      'friends': FieldValue.arrayRemove([friendId]),
    });

    // Remove current user from friend's list
    final friendRef = _firestore.collection('users').doc(friendId);
    batch.update(friendRef, {
      'friends': FieldValue.arrayRemove([user.uid]),
    });

    await batch.commit();
  }
}
