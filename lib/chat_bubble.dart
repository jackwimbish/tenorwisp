import 'package:flutter/material.dart';
import 'widgets/video_player_widget.dart';

class ChatBubble extends StatelessWidget {
  final String? text;
  final String? imageUrl;
  final String? videoUrl;
  final bool isMe;

  const ChatBubble({
    super.key,
    this.text,
    this.imageUrl,
    this.videoUrl,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (imageUrl != null) {
      return Image.network(imageUrl!);
    }
    if (videoUrl != null) {
      return VideoPlayerWidget(videoUrl: videoUrl!);
    }
    return Text(
      text ?? '',
      style: TextStyle(
        color: isMe
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSecondary,
      ),
    );
  }
}
