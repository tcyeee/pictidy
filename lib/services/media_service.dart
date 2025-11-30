import 'dart:io';
import 'package:flutter/foundation.dart';
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

  /// 加载 macOS Photos 库中的媒体文件
  /// [photosLibraryPath] 可以是 Photos 库的路径，如果为 null 则尝试默认路径
  static Future<List<MediaItem>> loadMediaFromPhotosLibrary([String? photosLibraryPath]) async {
    try {
      String? targetPath = photosLibraryPath;
      
      // 如果没有提供路径，尝试默认路径
      if (targetPath == null || targetPath.isEmpty) {
        final homeDir = Platform.environment['HOME'];
        if (homeDir == null) {
          throw Exception('无法获取用户主目录');
        }
        targetPath = path.join(homeDir, 'Pictures', 'Photos Library.photoslibrary');
      }

      // 处理 .photoslibrary 包路径
      // 如果路径以 .photoslibrary 结尾，需要访问包内的内容
      final photosLibraryDir = Directory(targetPath);
      
      if (!await photosLibraryDir.exists()) {
        throw Exception('未找到 Photos 库，路径: $targetPath');
      }

      final List<MediaItem> mediaItems = [];
      
      // Photos 库的结构（.photoslibrary 是一个包）：
      // - originals/ - 原始图片（新版本 Photos）
      // - Masters/ - 主图片（旧版本 iPhoto）
      // - resources/ - 资源文件
      // - private/var/folders/... - 可能包含实际文件（新版本）
      
      final possiblePaths = [
        path.join(targetPath, 'originals'),
        path.join(targetPath, 'Masters'),
        path.join(targetPath, 'resources', 'originals'),
        path.join(targetPath, 'private', 'var'),
      ];

      debugPrint('开始搜索 Photos 库，路径: $targetPath');
      
      for (final dirPath in possiblePaths) {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          debugPrint('找到目录: $dirPath');
          try {
            final beforeCount = mediaItems.length;
            await _loadMediaFromDirectoryRecursive(dir, mediaItems);
            final afterCount = mediaItems.length;
            debugPrint('从 $dirPath 加载了 ${afterCount - beforeCount} 个媒体文件');
          } catch (e) {
            debugPrint('访问目录 $dirPath 失败: $e');
            // 如果某个目录访问失败，继续尝试其他目录
            continue;
          }
        } else {
          debugPrint('目录不存在: $dirPath');
        }
      }

      // 如果上述路径都没有找到，尝试直接搜索整个 Photos 库
      if (mediaItems.isEmpty) {
        debugPrint('尝试搜索整个 Photos 库...');
        try {
          await _loadMediaFromDirectoryRecursive(photosLibraryDir, mediaItems);
          debugPrint('从整个库中加载了 ${mediaItems.length} 个媒体文件');
        } catch (e) {
          debugPrint('搜索整个库失败: $e');
        }
      }

      debugPrint('总共找到 ${mediaItems.length} 个媒体文件');

      // 按修改时间排序，最新的在前
      mediaItems.sort((a, b) {
        final aTime = a.dateModified ?? DateTime(1970);
        final bTime = b.dateModified ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      return mediaItems;
    } catch (e) {
      debugPrint('loadMediaFromPhotosLibrary 错误: $e');
      rethrow;
    }
  }

  /// 递归加载目录中的媒体文件
  static Future<void> _loadMediaFromDirectoryRecursive(
    Directory directory,
    List<MediaItem> mediaItems, {
    int maxDepth = 10,
    int currentDepth = 0,
  }) async {
    if (currentDepth >= maxDepth) {
      return; // 防止无限递归
    }
    
    try {
      final files = directory.listSync(followLinks: false);
      int foundInThisDir = 0;
      
      for (var file in files) {
        try {
          if (file is File && isMediaFile(file.path)) {
            try {
              final stat = await file.stat();
              mediaItems.add(MediaItem(
                file: file,
                isVideo: isVideoFile(file.path),
                dateModified: stat.modified,
              ));
              foundInThisDir++;
            } catch (e) {
              // 如果无法读取文件信息，跳过
              continue;
            }
          } else if (file is Directory) {
            // 递归搜索子目录
            try {
              await _loadMediaFromDirectoryRecursive(
                file,
                mediaItems,
                maxDepth: maxDepth,
                currentDepth: currentDepth + 1,
              );
            } catch (e) {
              // 如果子目录访问失败，继续
              continue;
            }
          }
        } catch (e) {
          // 跳过无法访问的文件/目录
          continue;
        }
      }
      
      if (foundInThisDir > 0) {
        debugPrint('在 ${directory.path} 中找到 $foundInThisDir 个媒体文件');
      }
    } catch (e) {
      // 如果目录访问失败，记录但不抛出异常（允许继续搜索其他目录）
      debugPrint('访问目录 ${directory.path} 失败: $e');
    }
  }
}

