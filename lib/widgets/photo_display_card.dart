import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// 照片显示卡片组件
/// 
/// 用于显示加载的照片，支持文件路径和字节数据两种方式
class PhotoDisplayCard extends StatelessWidget {
  /// 照片文件路径（如果通过文件方式加载）
  final String? imagePath;

  /// 照片字节数据（如果通过字节方式加载）
  final Uint8List? imageData;

  const PhotoDisplayCard({
    super.key,
    this.imagePath,
    this.imageData,
  });

  /// 检查是否有有效数据
  bool get hasData => imagePath != null || (imageData != null && imageData!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    if (!hasData) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text(
              '第一张照片',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // 根据数据类型选择不同的显示方式
            imagePath != null
                ? Image.file(
                    File(imagePath!),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Text('加载失败: $error');
                    },
                  )
                : Image.memory(
                    imageData!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Text('加载失败: $error');
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

