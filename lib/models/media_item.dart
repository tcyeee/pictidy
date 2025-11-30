import 'dart:io';

class MediaItem {
  final File file;
  final bool isVideo;
  final bool isFavorite;
  final String? albumName;
  final DateTime? dateModified;

  MediaItem({
    required this.file,
    required this.isVideo,
    this.isFavorite = false,
    this.albumName,
    this.dateModified,
  });

  String get name => file.path.split(Platform.pathSeparator).last;
  String get path => file.path;
}

