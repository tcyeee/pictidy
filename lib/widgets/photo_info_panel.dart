import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

/// 照片信息面板组件
///
/// 显示当前选中照片的详细信息
class PhotoInfoPanel extends StatelessWidget {
  /// 当前选中的照片实体
  final AssetEntity? asset;

  const PhotoInfoPanel({
    super.key,
    this.asset,
  });

  @override
  Widget build(BuildContext context) {
    if (asset == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            '请选择一张照片查看详细信息',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('基本信息'),
          _buildInfoRow('ID', asset!.id),
          _buildInfoRow('类型', _getTypeString(asset!.type)),
          _buildInfoRow('宽度', '${asset!.width} px'),
          _buildInfoRow('高度', '${asset!.height} px'),
          _buildInfoRow('尺寸', '${asset!.size.width.toInt()} × ${asset!.size.height.toInt()}'),
          _buildInfoRow('是否收藏', asset!.isFavorite ? '是' : '否'),
          const SizedBox(height: 16),
          _buildSectionTitle('时间信息'),
          _buildInfoRow('创建时间', _formatDateTime(asset!.createDateTime)),
          _buildInfoRow('修改时间', _formatDateTime(asset!.modifiedDateTime)),
          const SizedBox(height: 16),
          _buildSectionTitle('位置信息'),
          if (asset!.latitude != 0.0 && asset!.longitude != 0.0) ...[
            _buildInfoRow('纬度', '${asset!.latitude}'),
            _buildInfoRow('经度', '${asset!.longitude}'),
          ] else
            _buildInfoRow('位置', '无位置信息'),
          const SizedBox(height: 16),
          _buildSectionTitle('其他信息'),
          _buildInfoRow('方向', '${asset!.orientation}'),
          if (asset!.type == AssetType.video) ...[
            _buildInfoRow('时长', '${asset!.duration} 秒'),
          ],
        ],
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取类型字符串
  String _getTypeString(AssetType type) {
    switch (type) {
      case AssetType.image:
        return '图片';
      case AssetType.video:
        return '视频';
      case AssetType.audio:
        return '音频';
      case AssetType.other:
        return '其他';
    }
  }


  /// 格式化日期时间
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '未知';
    }
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }
}

