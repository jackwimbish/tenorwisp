import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ThreadDetailScreen extends StatefulWidget {
  final String threadTitle;

  const ThreadDetailScreen({super.key, required this.threadTitle});

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  // Dummy data for posts, including text and images
  static final List<Map<String, dynamic>> _dummyPosts = [
    {
      'type': 'text',
      'author_username': 'AI_Enthusiast',
      'postText':
          'I think it will be a powerful new tool for artists, not a replacement. It opens up entirely new mediums.',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 55)),
    },
    {
      'type': 'text',
      'author_username': 'Art_Historian',
      'postText':
          'This whole debate feels very similar to the initial reaction to photography in the 19th century. Many painters thought it was the end of their craft.',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 48)),
    },
    {
      'type': 'image',
      'author_username': 'VisualThinker',
      'imageUrl': 'https://picsum.photos/seed/abstractart/600/400',
      'postText': 'Here\'s an example of what can be created.',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 30)),
    },
    {
      'type': 'text',
      'author_username': 'DeepThought',
      'postText':
          'The real question is about intent and authorship. If an AI generates an image, who is the artist? The AI, the person who wrote the prompt, or the developers who built the model?',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 25)),
    },
    {
      'type': 'image',
      'author_username': 'Old_Master',
      'imageUrl': 'https://picsum.photos/seed/renaissance/600/400',
      'postText': 'A timeless classic for comparison.',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 10)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.threadTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _dummyPosts.length,
              itemBuilder: (context, index) {
                final post = _dummyPosts[index];
                return _PostWidget(post: post);
              },
            ),
          ),
          SafeArea(child: _buildReplyComposer()),
        ],
      ),
    );
  }

  Widget _buildReplyComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: const InputDecoration(
                hintText: 'Post your reply...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_replyController.text.isNotEmpty) {
                _replyController.clear();
                FocusScope.of(context).unfocus(); // Hide keyboard
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Replying is not yet implemented.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
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
