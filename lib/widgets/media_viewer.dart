import 'package:flutter/material.dart';
import 'package:pictidy/models/media_item.dart';
import 'package:video_player/video_player.dart';

class MediaViewer extends StatefulWidget {
  final MediaItem item;

  const MediaViewer({super.key, required this.item});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.isVideo) {
      _initializeVideo();
    } else {
      _isInitialized = true;
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.file(widget.item.file);
    await _videoController!.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (widget.item.isVideo) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoController!),
            Positioned(
              bottom: 10,
              child: VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
              ),
            ),
            Center(
              child: IconButton(
                icon: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 50,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
              ),
            ),
          ],
        ),
      );
    } else {
      return Image.file(
        widget.item.file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
          );
        },
      );
    }
  }
}

