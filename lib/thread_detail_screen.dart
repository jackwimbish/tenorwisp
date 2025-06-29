import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:tenorwisp/widgets/post_bubble.dart';
import 'package:tenorwisp/service_locator.dart';
import 'package:tenorwisp/services/user_service.dart';
import 'package:tenorwisp/services/auth_service.dart';

class ThreadDetailScreen extends StatefulWidget {
  final String threadId;

  const ThreadDetailScreen({super.key, required this.threadId});

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final _commentController = TextEditingController();
  final UserService _userService = getIt<UserService>();
  final AuthService _authService = getIt<AuthService>();

  Future<void> _postComment() async {
    final authUser = _userService.currentUser;
    final text = _commentController.text.trim();

    if (authUser == null || text.isEmpty) return;

    // Fetch the user's profile from the 'users' collection
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(authUser.uid)
        .get();
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
    FocusScope.of(context).unfocus();
  }

  Future<void> _showFriendRequestDialog(String authorId) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null || currentUser.uid == authorId) {
      return;
    }

    // Check if a request has already been sent or if they are already friends
    final userDoc = await _userService.getUserDocStream(currentUser.uid).first;
    final userData = userDoc.data() as Map<String, dynamic>?;
    final sentRequests =
        (userData?['friendRequestsSent'] as List?)?.cast<String>() ?? [];
    final friends = (userData?['friends'] as List?)?.cast<String>() ?? [];

    if (sentRequests.contains(authorId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request already sent.')),
      );
      return;
    }

    if (friends.contains(authorId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You are already friends.')));
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send Friend Request?'),
          content: const Text(
            'Do you want to send a friend request to this user?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Send'),
              onPressed: () async {
                try {
                  await _userService.sendFriendRequest(authorId);
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Friend request sent successfully!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to send request: ${e.toString()}',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thread"), // Placeholder title
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No posts yet."));
                }

                final posts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final postData =
                        posts[index].data() as Map<String, dynamic>;
                    // Use our new PostBubble widget for each post
                    return PostBubble(
                      postData: postData,
                      onAuthorTapped: _showFriendRequestDialog,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "Add a comment...",
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _postComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// A dedicated widget to render a single post
class _PostWidget extends StatelessWidget {
  final Map<String, dynamic> post;

  const _PostWidget({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(
                    Icons.person,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  post['author_username'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  timeago.format(post['createdAt']),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content
            if (post['type'] == 'image')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post['postText'] != null && post['postText'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(post['postText']),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      post['imageUrl'],
                      loadingBuilder: (context, child, progress) {
                        return progress == null
                            ? child
                            : const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ],
              )
            else
              Text(post['postText']),
          ],
        ),
      ),
    );
  }
}
