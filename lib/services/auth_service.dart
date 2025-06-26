import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // 1. Check if username is already taken
      final usernameDoc = await _firestore
          .collection('usernames')
          .doc(username)
          .get();
      if (usernameDoc.exists) {
        throw Exception('Username is already taken.');
      }

      // 2. If username is available, create the user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Set up user data in a batched write
      final user = userCredential.user;
      if (user != null) {
        final avatarUrl =
            'https://api.dicebear.com/8.x/adventurer/svg?seed=${user.uid}';

        await user.updateDisplayName(username);
        await user.updatePhotoURL(avatarUrl);

        WriteBatch batch = _firestore.batch();

        // Create user document
        final userDocRef = _firestore.collection('users').doc(user.uid);
        batch.set(userDocRef, {
          'email': user.email,
          'username': username,
          'photoURL': avatarUrl,
        });

        // Create username document for uniqueness
        final usernameDocRef = _firestore.collection('usernames').doc(username);
        batch.set(usernameDocRef, {'uid': user.uid});

        await batch.commit();
      }
      return userCredential;
    } on FirebaseAuthException {
      // Re-throw the exception to be handled by the UI
      rethrow;
    } catch (e) {
      // For other exceptions, wrap them in a standard format if needed
      // or just rethrow.
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      // Handle potential errors, e.g., log them
      print('Error signing out: $e');
      rethrow;
    }
  }
}
