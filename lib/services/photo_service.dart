import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

/// 照片加载结果数据类
/// 包含照片的文件路径或字节数据
class PhotoLoadResult {
  /// 照片文件路径（如果通过文件方式加载）
  final String? filePath;

  /// 照片字节数据（如果通过字节方式加载）
  final Uint8List? imageData;

  /// 是否成功加载
  final bool success;

  /// 错误信息（如果加载失败）
  final String? errorMessage;

  PhotoLoadResult({this.filePath, this.imageData, required this.success, this.errorMessage});

  /// 检查是否有有效数据
  bool get hasData => filePath != null || (imageData != null && imageData!.isNotEmpty);
}

/// 照片服务类
/// 负责从相册中加载照片数据
class PhotoService {
  /// 单例实例
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  /// 获取相册列表的超时时间
  static const Duration _albumListTimeout = Duration(seconds: 5);

  /// 获取所有相册列表
  ///
  /// [type] 请求的资源类型，默认为图片
  /// [hasAll] 是否包含所有相册
  /// 返回相册路径实体列表
  Future<List<AssetPathEntity>> getAlbumList({RequestType type = RequestType.image, bool hasAll = true}) async {
    try {
      final paths = await PhotoManager.getAssetPathList(type: type, hasAll: hasAll).timeout(
        _albumListTimeout,
        onTimeout: () {
          throw TimeoutException('获取相册列表超时');
        },
      );
      return paths;
    } catch (e) {
      throw Exception('获取相册列表失败: $e');
    }
  }

  /// 从指定相册获取照片列表
  ///
  /// [path] 相册路径实体
  /// [page] 页码，从0开始
  /// [size] 每页数量
  /// 返回照片实体列表
  Future<List<AssetEntity>> getPhotosFromAlbum(AssetPathEntity path, {int page = 0, int size = 1}) async {
    try {
      final assets = await path.getAssetListPaged(page: page, size: size);
      return assets;
    } catch (e) {
      throw Exception('从相册获取照片失败: $e');
    }
  }

  /// 加载第一张照片
  ///
  /// 会尝试多种方法加载照片数据：
  /// 1. originFile - 获取原始文件
  /// 2. originBytes - 获取原始字节数据
  /// 3. file - 获取文件
  /// 4. thumbnailData - 获取缩略图数据
  ///
  /// 返回 PhotoLoadResult 对象，包含加载结果
  Future<PhotoLoadResult> loadFirstPhoto() async {
    try {
      // 步骤1: 获取相册列表
      final paths = await getAlbumList();
      if (paths.isEmpty) {
        return PhotoLoadResult(success: false, errorMessage: '未找到任何相册');
      }

      // 步骤2: 从第一个相册获取照片
      final firstPath = paths.first;
      final assets = await getPhotosFromAlbum(firstPath, page: 0, size: 1);
      if (assets.isEmpty) {
        return PhotoLoadResult(success: false, errorMessage: '相册中没有照片');
      }

      // 步骤3: 尝试多种方法加载第一张照片
      final firstAsset = assets.first;
      return await _loadAssetData(firstAsset);
    } catch (e) {
      return PhotoLoadResult(success: false, errorMessage: '加载照片时出错: $e');
    }
  }

  /// 加载多张照片的缩略图
  ///
  /// [count] 要加载的照片数量，默认20张
  /// 返回照片实体列表
  Future<List<AssetEntity>> loadPhotoThumbnails({int count = 20}) async {
    try {
      // 获取相册列表
      final paths = await getAlbumList();
      if (paths.isEmpty) {
        return [];
      }

      // 从第一个相册获取照片
      final firstPath = paths.first;
      final assets = await getPhotosFromAlbum(firstPath, page: 0, size: count);
      return assets;
    } catch (e) {
      debugPrint('加载照片缩略图失败: $e');
      return [];
    }
  }

  /// 加载指定照片的完整数据
  ///
  /// [asset] 照片实体
  /// 返回 PhotoLoadResult 对象
  Future<PhotoLoadResult> loadPhotoData(AssetEntity asset) async {
    return await _loadAssetData(asset);
  }

  /// 加载照片资源数据
  ///
  /// 尝试多种方法获取照片数据，按优先级顺序：
  /// 1. originFile - 原始文件（最佳质量）
  /// 2. originBytes - 原始字节数据
  /// 3. file - 文件
  /// 4. thumbnailData - 缩略图（最后备选）
  Future<PhotoLoadResult> _loadAssetData(AssetEntity asset) async {
    // 方法1: 尝试获取原始文件
    try {
      final file = await asset.originFile;
      if (file != null) {
        return PhotoLoadResult(filePath: file.path, success: true);
      }
    } catch (e) {
      // 继续尝试其他方法
    }

    // 方法2: 尝试获取原始字节数据
    try {
      final imageData = await asset.originBytes;
      if (imageData != null && imageData.isNotEmpty) {
        return PhotoLoadResult(imageData: imageData, success: true);
      }
    } catch (e) {
      // 继续尝试其他方法
    }

    // 方法3: 尝试获取文件
    try {
      final file = await asset.file;
      if (file != null) {
        return PhotoLoadResult(filePath: file.path, success: true);
      }
    } catch (e) {
      // 继续尝试其他方法
    }

    // 方法4: 尝试获取缩略图（最后备选方案）
    try {
      final thumbnailData = await asset.thumbnailData;
      if (thumbnailData != null && thumbnailData.isNotEmpty) {
        return PhotoLoadResult(imageData: thumbnailData, success: true);
      }
    } catch (e) {
      // 所有方法都失败
    }

    // 所有方法都失败
    return PhotoLoadResult(success: false, errorMessage: '所有加载方法都失败了');
  }
}
