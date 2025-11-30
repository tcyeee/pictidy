import 'dart:io';
import 'package:pictidy/models/media_item.dart';
import 'package:path/path.dart' as path;

class MediaService {
  static final List<String> imageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.heif'
  ];
  
  static final List<String> videoExtensions = [
    '.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv', '.wmv', '.m4v'
  ];

  static bool isImageFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return imageExtensions.contains(ext);
  }

  static bool isVideoFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return videoExtensions.contains(ext);
  }

  static bool isMediaFile(String filePath) {
    return isImageFile(filePath) || isVideoFile(filePath);
  }

  static Future<List<MediaItem>> loadMediaFromDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return [];
    }

    final List<MediaItem> mediaItems = [];
    final files = directory.listSync(recursive: true);

    for (var file in files) {
      if (file is File && isMediaFile(file.path)) {
        final stat = await file.stat();
        mediaItems.add(MediaItem(
          file: file,
          isVideo: isVideoFile(file.path),
          dateModified: stat.modified,
        ));
      }
    }

    // 按修改时间排序，最新的在前
    mediaItems.sort((a, b) {
      final aTime = a.dateModified ?? DateTime(1970);
      final bTime = b.dateModified ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    return mediaItems;
  }

  static Future<bool> deleteMedia(MediaItem item) async {
    try {
      if (await item.file.exists()) {
        await item.file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

