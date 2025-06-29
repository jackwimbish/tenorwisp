import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubmissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? get userDocStream {
    if (currentUser == null) return null;
    return _firestore.collection('users').doc(currentUser!.uid).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getSubmissionStream(
    String submissionId,
  ) {
    return _firestore.collection('submissions').doc(submissionId).snapshots();
  }

  Future<Map<String, dynamic>> submitIdea(String submissionText) async {
    final user = currentUser;
    if (user == null || submissionText.isEmpty) {
      throw Exception('User not logged in or submission text is empty.');
    }

    final newSubmissionRef = _firestore.collection('submissions').doc();
    final userDocRef = _firestore.collection('users').doc(user.uid);
    final clientTimestamp = Timestamp.now();

    final submissionDataForServer = {
      'author_uid': user.uid,
      'submissionText': submissionText,
      'createdAt': FieldValue.serverTimestamp(),
      'clientCreatedAt': clientTimestamp,
      'lastEdited': FieldValue.serverTimestamp(),
      'status': 'live',
    };

    final batch = _firestore.batch();

    batch.set(newSubmissionRef, submissionDataForServer);

    batch.update(userDocRef, {'live_submission_id': newSubmissionRef.id});

    await batch.commit();

    // Prepare data for immediate client-side use
    final submissionDataForClient = {
      'id': newSubmissionRef.id,
      'author_uid': user.uid,
      'submissionText': submissionText,
      'createdAt': clientTimestamp,
      'lastEdited': clientTimestamp,
      'status': 'live',
    };
    return submissionDataForClient;
  }

  Future<void> withdrawActiveSubmission(String submissionId) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }

    final submissionRef = _firestore
        .collection('submissions')
        .doc(submissionId);
    final userRef = _firestore.collection('users').doc(user.uid);

    final batch = _firestore.batch();

    batch.update(submissionRef, {'status': 'withdrawn'});
    batch.update(userRef, {'live_submission_id': FieldValue.delete()});

    await batch.commit();
  }
}
