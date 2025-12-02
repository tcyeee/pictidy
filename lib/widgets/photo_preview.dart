import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// 照片预览组件
///
/// 用于在右侧主区域显示当前选中的照片
class PhotoPreview extends StatelessWidget {
  /// 照片文件路径（如果通过文件方式加载）
  final String? imagePath;

  /// 照片字节数据（如果通过字节方式加载）
  final Uint8List? imageData;

  /// 是否正在加载
  final bool isLoading;

  const PhotoPreview({
    super.key,
    this.imagePath,
    this.imageData,
    this.isLoading = false,
  });

  /// 检查是否有有效数据
  bool get hasData => imagePath != null || (imageData != null && imageData!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : !hasData
                ? const Text(
                    '请从左侧选择一张照片',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  )
                : imagePath != null
                    ? InteractiveViewer(
                        // 支持缩放和拖拽
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.file(
                          File(imagePath!),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text(
                              '加载失败',
                              style: TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      )
                    : InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.memory(
                          imageData!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text(
                              '加载失败',
                              style: TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

