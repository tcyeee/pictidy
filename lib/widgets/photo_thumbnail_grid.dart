import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/photo_service.dart';

/// 照片缩略图网格组件
///
/// 显示相册中前20张照片的缩略图，支持点击选择照片
class PhotoThumbnailGrid extends StatefulWidget {
  /// 选中照片的回调
  final Function(AssetEntity)? onPhotoSelected;

  const PhotoThumbnailGrid({
    super.key,
    this.onPhotoSelected,
  });

  @override
  State<PhotoThumbnailGrid> createState() => _PhotoThumbnailGridState();
}

class _PhotoThumbnailGridState extends State<PhotoThumbnailGrid> {
  final PhotoService _photoService = PhotoService();
  List<AssetEntity> _photos = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadThumbnails();
  }

  /// 加载照片缩略图
  Future<void> _loadThumbnails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final photos = await _photoService.loadPhotoThumbnails(count: 20);
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载缩略图失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadThumbnails,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (_photos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('没有照片'),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 每行4张缩略图
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final asset = _photos[index];
        return _ThumbnailItem(
          asset: asset,
          onTap: () {
            widget.onPhotoSelected?.call(asset);
          },
        );
      },
    );
  }
}

/// 单个缩略图项组件
class _ThumbnailItem extends StatefulWidget {
  final AssetEntity asset;
  final VoidCallback onTap;

  const _ThumbnailItem({
    required this.asset,
    required this.onTap,
  });

  @override
  State<_ThumbnailItem> createState() => _ThumbnailItemState();
}

class _ThumbnailItemState extends State<_ThumbnailItem> {
  Uint8List? _thumbnailData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  /// 加载缩略图数据
  Future<void> _loadThumbnail() async {
    try {
      // 获取缩略图
      final thumbnail = await widget.asset.thumbnailData;
      if (mounted) {
        setState(() {
          _thumbnailData = thumbnail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _thumbnailData != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.memory(
                      _thumbnailData!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image);
                      },
                    ),
                  )
                : const Icon(Icons.image_not_supported),
      ),
    );
  }
}

