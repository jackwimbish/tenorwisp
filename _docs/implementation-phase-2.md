# Phase 2: Flutter User Submission Implementation Guide

**Goal:** Implement the complete user-facing submission loop.

By the end of this phase, a logged-in user will be able to submit their private topic idea. The app will save this data securely, update the user's profile to reflect their "live" submission, and provide clear UI feedback. This sets the stage perfectly for the backend to process this data in Phase 3.

## Step 1: Finalize Firestore Security Rules

This is the foundation for this phase. Before writing any Flutter code, you need to tell Firebase who is allowed to do what. These rules enable the client-side batched write we need for the prototype.

Deploy these rules to your Firebase project via the Firebase console.

### firestore.rules file:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // --- User Profile Rules ---
    match /users/{userId} {
      // A user can read their own profile to check for a live submission.
      allow read: if request.auth.uid == userId;

      // A user can update their own profile. For the prototype, this is broad.
      // In production, you might restrict which fields can be updated.
      allow update: if request.auth.uid == userId;
    }

    // --- Submissions Rules ---
    match /submissions/{submissionId} {
      // CREATE: Allow a user to create a submission if they are signed in
      // and are stamping their own UID on the document.
      allow create: if request.auth.uid == request.resource.data.author_uid;

      // READ & UPDATE: Allow a user to read or update their own submission
      // ONLY if its status is "live". This prevents editing archived submissions.
      allow read, update: if request.auth.uid == resource.data.author_uid
                          && resource.data.status == 'live';

      // DELETE: Disallow deletion by clients to preserve data for analytics.
      allow delete: if false;
    }

    // Rule for the public threads that will be created in Phase 3
    match /public_threads/{threadId} {
        allow read: if true;
        allow write: if false; // Only the backend can write here
    }
  }
}
```

## Step 2: Implement the Flutter Submission UI

In your Flutter app, you'll need a dedicated screen or view where users can submit their ideas.

1. Create a new screen (e.g., `SubmissionScreen.dart`)
2. **Build the UI:** This screen will contain:
   - A `TextField` or `TextFormField` for the user to type their idea. It should be multiline.
   - An `ElevatedButton` for submitting.
3. **State Management:** Use a `StatefulWidget` to manage the text controller for the `TextField`. You can also add logic to disable the "Submit" button until the user has typed something.

```dart
// A basic UI structure in your widget's build method
Column(
  padding: const EdgeInsets.all(16.0),
  children: [
    Text(
      "What's on your mind?",
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 16),
    TextField(
      controller: _submissionController, // Your TextEditingController
      maxLines: 5,
      decoration: InputDecoration(
        hintText: "Share a topic idea for the next discussion...",
        border: OutlineInputBorder(),
      ),
    ),
    const SizedBox(height: 16),
    ElevatedButton(
      onPressed: _submit, // The function that triggers the batch write
      child: const Text('Submit Idea'),
    ),
  ],
)
```

## Step 3: Implement the Client-Side Batched Write

This is the core logic of this phase. This function ensures that creating the submission and linking it to the user's profile happen together as one single operation.

Add this function to the State class of your `SubmissionScreen`.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Inside your screen's State class...
Future<void> _submit() async {
  final user = FirebaseAuth.instance.currentUser;
  final submissionText = _submissionController.text.trim();

  // Basic validation
  if (user == null || submissionText.isEmpty) {
    // Show an error message if user is not logged in or text is empty
    return;
  }

  // Show a loading indicator
  setState(() { _isLoading = true; });

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
  batch.update(userDocRef, {
    'live_submission_id': newSubmissionRef.id,
  });

  // 6. Commit the batch. Both operations will either succeed or fail together.
  try {
    await batch.commit();
    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your submission has been received!')),
    );
  } catch (e) {
    // Show an error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
    );
  } finally {
    // Hide the loading indicator
    setState(() { _isLoading = false; });
  }
}
```

## Step 4: Create a "Submission Status" View

To create a good user experience, the app should show the user their current submission if they have one, instead of always showing the form. This also prevents them from submitting more than one idea per round.

You can wrap your entire screen's build method in a `StreamBuilder` that listens to the user's own document.

```dart
// At the top of your screen's build method...
final user = FirebaseAuth.instance.currentUser;

return StreamBuilder<DocumentSnapshot>(
  // Listen to the current user's document in the 'users' collection
  stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!snapshot.hasData || snapshot.data?.data() == null) {
      return const Center(child: Text("Could not load user data."));
    }

    final userData = snapshot.data!.data() as Map<String, dynamic>;
    final liveSubmissionId = userData['live_submission_id'];

    if (liveSubmissionId == null) {
      // If the user has NO live submission, show the creation form.
      return buildSubmissionForm(); // This would be the widget from Step 2
    } else {
      // If the user HAS a live submission, show its content.
      return buildSubmissionStatusView(liveSubmissionId);
    }
  },
);
```

The `buildSubmissionStatusView` would then fetch the specific document from the submissions collection and display its text, along with an "Edit" or "Withdraw" button.

## Step 5: Verification and Testing

1. Log into your Flutter app as a test user
2. Navigate to the submission screen. You should see the submission form
3. Type an idea and press "Submit"
4. **Check the UI:** Does the view now change to show the text you just submitted?
5. **Check Firestore:**
   - Go to the `submissions` collection. Is there a new document with the correct text, `author_uid`, and `status: "live"`?
   - Go to the `users` collection and find your test user's document. Does it have the `live_submission_id` field pointing to the correct new submission document?
6. Restart the app. Does it correctly show your existing submission instead of the form?
7. **(Optional)** Implement the "Edit" functionality, which would simply update the text in the existing submission document. Verify the security rules still allow this.