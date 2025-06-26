import 'package:flutter/material.dart';
import 'package:tenorwisp/widgets/video_player_widget.dart';

class ChatBubble extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isMe;

  const ChatBubble({super.key, required this.data, required this.isMe});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showVideoPlayer = false;

  Widget _buildContent(ThemeData theme) {
    final text = widget.data['text'] as String?;
    final imageUrl = widget.data['imageUrl'] as String?;
    final videoUrl = widget.data['videoUrl'] as String?;
    final thumbnailUrl = widget.data['thumbnailUrl'] as String?;
    final aspectRatio = widget.data['aspectRatio'] as double?;
    final status = widget.data['status'] as String?;

    // Video content
    if (thumbnailUrl != null && videoUrl != null) {
      final videoContent = _showVideoPlayer
          ? VideoPlayerWidget(videoUrl: videoUrl)
          : _buildThumbnail(thumbnailUrl);

      // Use AspectRatio to prevent layout jump
      return AspectRatio(
        aspectRatio: aspectRatio ?? 16 / 9,
        child: videoContent,
      );
    }

    // Image content
    if (imageUrl != null) {
      return Image.network(imageUrl);
    }

    // Uploading placeholder
    if (status == 'uploading') {
      return const SizedBox(
        width: 100,
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // Failed placeholder
    if (status == 'failed') {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(height: 4),
          Text('Upload Failed'),
        ],
      );
    }

    // Text content
    return Text(
      text ?? '',
      style: TextStyle(
        color: widget.isMe
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSecondary,
      ),
    );
  }

  Widget _buildThumbnail(String thumbnailUrl) {
    return GestureDetector(
      onTap: () => setState(() => _showVideoPlayer = true),
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          Image.network(thumbnailUrl, fit: BoxFit.cover),
          // Play button overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isMe
              ? theme.colorScheme.primary
              : theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _buildContent(theme),
      ),
    );
  }
}
