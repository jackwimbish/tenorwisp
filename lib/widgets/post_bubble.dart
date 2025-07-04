import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PostBubble extends StatelessWidget {
  final Map<String, dynamic> postData;
  final Function(String authorId)? onAuthorTapped;

  const PostBubble({super.key, required this.postData, this.onAuthorTapped});

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
            child: (photoURL != null && photoURL.isNotEmpty)
                ? ClipOval(
                    child: _isSvgUrl(photoURL)
                        ? SvgPicture.network(
                            photoURL,
                            fit: BoxFit.cover,
                            placeholderBuilder: (context) => const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                              ),
                            ),
                          )
                        : Image.network(
                            photoURL,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person),
                          ),
                  )
                : const Icon(Icons.person),
          );

    final authorInfo = Row(
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
            ],
          ),
        ),
      ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAIPost)
            authorInfo
          else
            GestureDetector(
              onTap: () {
                if (onAuthorTapped != null) {
                  onAuthorTapped!(postData['author_uid']);
                }
              },
              child: authorInfo,
            ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.only(
              left: 52.0,
            ), // Aligns text with avatar
            child: Text(postData['postText'] ?? ''),
          ),
        ],
      ),
    );
  }

  bool _isSvgUrl(String urlString) {
    try {
      final uri = Uri.parse(urlString);
      return uri.path.endsWith('.svg') || uri.path.endsWith('/svg');
    } catch (e) {
      // If parsing fails, treat it as not an SVG
      return false;
    }
  }
}
