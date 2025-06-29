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
              color: theme.colorScheme.onTertiaryContainer,
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
        border: isAIPost
            ? Border.all(color: theme.colorScheme.outlineVariant)
            : null,
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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
