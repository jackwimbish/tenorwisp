import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SubmissionScreen extends StatefulWidget {
  const SubmissionScreen({super.key});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final _submissionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    final submissionText = _submissionController.text.trim();

    // Basic validation
    if (user == null || submissionText.isEmpty) {
      // Show an error message if user is not logged in or text is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in and provide text to submit.'),
        ),
      );
      return;
    }

    // Show a loading indicator
    setState(() {
      _isLoading = true;
    });

    final firestore = FirebaseFirestore.instance;

    // 1. Create a reference for the new submission document to get its ID.
    final newSubmissionRef = firestore.collection('submissions').doc();

    // 2. Create a reference to the current user's document.
    final userDocRef = firestore.collection('users').doc(user.uid);

    // 3. Create the write batch.
    final batch = firestore.batch();

    // 4. Stage the creation of the new submission document.
    batch.set(newSubmissionRef, {
      'author_uid': user.uid,
      'submissionText': submissionText,
      'createdAt': FieldValue.serverTimestamp(),
      'lastEdited': FieldValue.serverTimestamp(),
      'status': 'live', // All new submissions are 'live'
    });

    // 5. Stage the update to the user's document, linking the new submission.
    batch.update(userDocRef, {'live_submission_id': newSubmissionRef.id});

    // 6. Commit the batch. Both operations will either succeed or fail together.
    try {
      await batch.commit();
      // Show a success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your submission has been received!')),
      );
      // Optionally, pop the screen
      // Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      // Show an error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    } finally {
      // Hide the loading indicator
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _withdrawSubmission(String submissionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    final firestore = FirebaseFirestore.instance;
    final submissionRef = firestore.collection('submissions').doc(submissionId);
    final userRef = firestore.collection('users').doc(user.uid);

    final batch = firestore.batch();

    // 1. Mark the submission as 'withdrawn' instead of deleting
    batch.update(submissionRef, {'status': 'withdrawn'});

    // 2. Remove the link from the user's profile
    batch.update(userRef, {'live_submission_id': FieldValue.delete()});

    try {
      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your submission has been withdrawn.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while withdrawing: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share an Idea'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      // Listen to the user's document to check for a live submission
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData ||
              snapshot.hasError ||
              snapshot.data?.data() == null) {
            return const Center(child: Text("Could not load user data."));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          // Use .get() to safely access the field, which might not exist
          final liveSubmissionId = userData.containsKey('live_submission_id')
              ? userData['live_submission_id']
              : null;

          if (liveSubmissionId == null) {
            // If the user has NO live submission, show the creation form.
            return _buildSubmissionForm();
          } else {
            // If the user HAS a live submission, show its content.
            return _buildSubmissionStatusView(liveSubmissionId);
          }
        },
      ),
    );
  }

  // --- UI for Creating a Submission ---
  Widget _buildSubmissionForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "What's on your mind?",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _submissionController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: "Share a topic idea for the next discussion...",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: Theme.of(context).textTheme.titleMedium,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit Idea'),
          ),
        ],
      ),
    );
  }

  // --- UI for Viewing an Existing Submission ---
  Widget _buildSubmissionStatusView(String submissionId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('submissions')
          .doc(submissionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.hasError || !snapshot.data!.exists) {
          return const Center(
            child: Text(
              "Could not load your submission. It may have been withdrawn.",
            ),
          );
        }

        final submissionData = snapshot.data!.data() as Map<String, dynamic>;
        final submissionText = submissionData['submissionText'];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your Active Submission:",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    submissionText,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit"),
                    onPressed: () {
                      // TODO: Implement edit functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Edit functionality not implemented yet.',
                          ),
                        ),
                      );
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Withdraw"),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () => _withdrawSubmission(submissionId),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
