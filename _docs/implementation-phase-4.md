### **Goal: Display the AI-generated threads in the Flutter app and allow user interaction.**

By the end of this phase, your app will have a fully functional loop. The user will be able to see the generated threads in real-time, tap into a thread to read the initial post, and add their own comments, creating a complete and demonstrable user experience.

### **Step 1: Create the Main Discussions Screen UI**

This screen will be the primary view of your "Discussions" tab, showing a list of all available threads.

1. **Create a new screen** file, for example, discussions_screen.dart.  
2. **Use a StreamBuilder:** This is the most critical widget for this screen. It will listen to your public_threads collection and automatically update the UI whenever a new thread is created by your backend.  
3. **Query and Order:** The StreamBuilder's stream should query the collection and order the threads by their creation date, so the newest ones are always at the top.  
4. **Handle UI States:** The builder must handle all possible connection states:  
   * **Waiting:** Show a CircularProgressIndicator.  
   * **Error:** Show a user-friendly error message.  
   * **No Data:** If the stream is empty, show a welcoming message like "No discussions yet. Check back soon!"  
   * **Has Data:** Build a ListView of the threads.

**Code Snippet for discussions_screen.dart:**

import 'package:flutter/material.dart';  
import 'package:cloud_firestore/cloud_firestore.dart';  
// Import your thread detail screen file here  
// import 'thread_detail_screen.dart'; 

class DiscussionsScreen extends StatelessWidget {  
  const DiscussionsScreen({super.key});

  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      appBar: AppBar(  
        title: const Text("Discussions"),  
      ),  
      body: StreamBuilder<QuerySnapshot>(  
        // 1. Define the stream to listen to  
        stream: FirebaseFirestore.instance  
            .collection('public_threads')  
            .orderBy('generatedAt', descending: true)  
            .snapshots(),  
          
        // 2. Build the UI based on the stream's state  
        builder: (context, snapshot) {  
          // Handle loading state  
          if (snapshot.connectionState == ConnectionState.waiting) {  
            return const Center(child: CircularProgressIndicator());  
          }

          // Handle error state  
          if (snapshot.hasError) {  
            return const Center(child: Text("Something went wrong."));  
          }

          // Handle no data state  
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {  
            return const Center(  
              child: Text(  
                "No discussions have started yet.nCheck back soon!",  
                textAlign: TextAlign.center,  
              ),  
            );  
          }

          // If we have data, build the list  
          final threads = snapshot.data!.docs;

          return ListView.builder(  
            itemCount: threads.length,  
            itemBuilder: (context, index) {  
              final threadData = threads[index].data() as Map<String, dynamic>;  
              final threadId = threads[index].id;

              return Card(  
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),  
                child: ListTile(  
                  title: Text(threadData['title'] ?? 'Untitled Thread'),  
                  subtitle: Text('Generated on: ${threadData['generatedAt']?.toDate().toString() ?? '...'}'),  
                  onTap: () {  
                    // Navigate to the detail screen, passing the thread ID  
                    Navigator.of(context).push(  
                      MaterialPageRoute(  
                        builder: (context) => ThreadDetailScreen(threadId: threadId),  
                      ),  
                    );  
                  },  
                ),  
              );  
            },  
          );  
        },  
      ),  
    );  
  }  
}

### **Step 2: Create the Thread Detail Screen**

This screen shows the actual conversation: the initial AI post and all subsequent user comments.

1. **Create a new screen** file, thread_detail_screen.dart. It will be a StatefulWidget and accept a threadId parameter in its constructor.  
2. **Structure the UI:** The screen will have a Column containing:  
   * A ListView or Expanded StreamBuilder to display the posts.  
   * A bottom section with a TextField for typing a new comment and an IconButton to send it.  
3. **Listen to Posts:** Use a StreamBuilder to listen to the posts sub-collection for the given threadId, ordered by creation time.  
4. **Implement Comment Submission:** The "Send" button's onPressed handler will:  
   * Get the current user's UID from Firebase Auth.  
   * **Fetch the user's profile document from the `users` collection in Firestore** to get their `username` and `photoURL`. This ensures the most up-to-date profile information is used.  
   * Create a new document in the `/public_threads/{threadId}/posts` sub-collection with the comment data.  
   * Clear the TextField after submission.

**Code Snippet for thread_detail_screen.dart:**

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThreadDetailScreen extends StatefulWidget {  
  final String threadId;  
  const ThreadDetailScreen({super.key, required this.threadId});

  @override  
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();  
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {  
  final _commentController = TextEditingController();

  Future<void> _postComment() async {  
    final authUser = FirebaseAuth.instance.currentUser;  
    final text = _commentController.text.trim();

    if (authUser == null || text.isEmpty) return;

    // Fetch the user's profile from the 'users' collection
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(authUser.uid).get();
    final userData = userDoc.data();
    
    final username = userData?['username'] ?? 'Anonymous';
    final photoURL = userData?['photoURL'];

    await FirebaseFirestore.instance  
        .collection('public_threads')  
        .doc(widget.threadId)  
        .collection('posts')  
        .add({  
      'postText': text,  
      'author_uid': authUser.uid,  
      'author_username': username,  
      'author_photoURL': photoURL,  
      'createdAt': FieldValue.serverTimestamp(),  
    });

    _commentController.clear();  
  }

  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      appBar: AppBar(title: const Text("Thread")),  
      body: Column(  
        children: [  
          Expanded(  
            child: StreamBuilder<QuerySnapshot>(  
              stream: FirebaseFirestore.instance  
                  .collection('public_threads')  
                  .doc(widget.threadId)  
                  .collection('posts')  
                  .orderBy('createdAt')  
                  .snapshots(),  
              builder: (context, snapshot) {  
                if (snapshot.connectionState == ConnectionState.waiting) {  
                  return const Center(child: CircularProgressIndicator());  
                }  
                if (!snapshot.hasData) return const SizedBox.shrink();

                final posts = snapshot.data!.docs;

                return ListView.builder(  
                  itemCount: posts.length,  
                  itemBuilder: (context, index) {  
                    final postData = posts[index].data() as Map<String, dynamic>;
                    // Use our new PostBubble widget for each post
                    return PostBubble(postData: postData);
                  },  
                );  
              },  
            ),  
          ),  
          // Input area  
          Padding(  
            padding: const EdgeInsets.all(8.0),  
            child: Row(  
              children: [  
                Expanded(  
                  child: TextField(  
                    controller: _commentController,  
                    decoration: const InputDecoration(hintText: "Add a comment..."),  
                  ),  
                ),  
                IconButton(  
                  icon: const Icon(Icons.send),  
                  onPressed: _postComment,  
                ),  
              ],  
            ),  
          ),  
        ],  
      ),  
    );  
  }  
}

### Step 3: Create a Polished `PostBubble` Widget

To create a more polished and intuitive UI, you'll create a dedicated widget for displaying individual posts. This widget will be able to differentiate between AI-generated and user-generated content.

1.  **Create `post_bubble.dart`:** Create a new file for a `StatefulWidget` named `PostBubble`.
2.  **Adapt from `ChatBubble`:** Use `lib/chat_bubble.dart` as a reference. The new `PostBubble` will have a similar structure but will be adapted for public posts. It should handle displaying `postText`. While the current data model doesn't include media, designing it like `ChatBubble` will make it easy to add image/video display in the future.
3.  **Differentiate AI vs. User Posts:** The key feature is to check the `author_uid` field of the post data.
    *   **If `author_uid` is `null`:** This is an AI-generated post. Style it as a special "starter" post. You could use a different background color and display a unique avatar (e.g., an icon for the app) and a username like "Thread Starter".
    *   **If `author_uid` is not `null`:** This is a user comment. Display the user's `author_photoURL` and `author_username`. You can align these bubbles to the left or right, or use a consistent alignment for all comments.

**Code Snippet for post_bubble.dart:**

```dart
import 'package:flutter/material.dart';

class PostBubble extends StatelessWidget {
  final Map<String, dynamic> postData;

  const PostBubble({super.key, required this.postData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAIPost = postData['author_uid'] == null;

    final authorName = isAIPost 
      ? "Thread Starter" 
      : postData['author_username'] ?? 'User';
    
    final photoURL = postData['author_photoURL'] as String?;

    final avatar = isAIPost
      ? CircleAvatar(
          backgroundColor: theme.colorScheme.tertiaryContainer,
          child: Icon(
            Icons.auto_awesome, 
            color: theme.colorScheme.onTertiaryContainer
          ),
        )
      : CircleAvatar(
          backgroundImage: (photoURL != null && photoURL.isNotEmpty) 
            ? NetworkImage(photoURL) 
            : null,
          child: (photoURL == null || photoURL.isEmpty) 
            ? const Icon(Icons.person) 
            : null,
        );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isAIPost 
          ? theme.colorScheme.surfaceVariant 
          : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: isAIPost ? Border.all(color: theme.colorScheme.outlineVariant) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authorName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4.0),
                Text(postData['postText'] ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### **Step 4: Conduct the Full End-to-End Test for the Demo**

This is the final check to ensure everything works together as a cohesive whole.

1. **Clear Data:** Manually delete all documents in your submissions and public_threads collections in the Firebase console.  
2. **Seed Submissions:** Using your Flutter app, log in as 2-3 different fake users and have each submit a topic idea.  
3. **Trigger Backend:** From your local terminal, run your trigger_generation.py script.  
4. **Watch the App:**  
   * Observe the DiscussionsScreen. You should see a loading indicator, followed by the new thread titles appearing automatically in the list.  
   * Tap on one of the new threads.  
   * The ThreadDetailScreen should open and display the initial AI-generated post with its unique styling.  
   * Type a comment in the text field and press send.  
   * Your new comment should appear at the bottom of the list almost instantly, with your user avatar and name.

If this entire flow works smoothly, your prototype is complete and ready to be demonstrated.
