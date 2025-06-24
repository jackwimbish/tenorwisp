import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ChatBubble extends StatefulWidget {
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
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  Future<void>? _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null) {
      _initializeVideoPlayerFuture = _initializePlayer();
    }
  }

  @override
  void didUpdateWidget(covariant ChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoUrl != oldWidget.videoUrl) {
      // If the video URL changes, we need to dispose the old player and re-initialize.
      _disposePlayer();
      if (widget.videoUrl != null) {
        _initializeVideoPlayerFuture = _initializePlayer();
      }
    }
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl!),
    );
    await _videoPlayerController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
    );
  }

  void _disposePlayer() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
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

  Widget _buildContent(ThemeData theme) {
    if (widget.imageUrl != null) {
      return Image.network(widget.imageUrl!);
    }
    if (widget.videoUrl != null) {
      return FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError || _chewieController == null) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Could not play video.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              );
            }
            return AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      );
    }
    return Text(
      widget.text ?? '',
      style: TextStyle(
        color: widget.isMe
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSecondary,
      ),
    );
  }
}
