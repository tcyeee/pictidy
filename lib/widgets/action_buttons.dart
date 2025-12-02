import 'package:flutter/material.dart';

/// 操作按钮组组件
/// 
/// 包含权限相关的操作按钮：请求权限、检查权限状态、打开系统设置
class ActionButtons extends StatelessWidget {
  /// 是否正在加载中（加载时禁用所有按钮）
  final bool isLoading;

  /// 请求权限按钮的回调
  final VoidCallback? onRequestPermission;

  /// 检查权限状态按钮的回调
  final VoidCallback? onCheckPermission;

  /// 打开系统设置按钮的回调
  final VoidCallback? onOpenSettings;

  const ActionButtons({
    super.key,
    required this.isLoading,
    this.onRequestPermission,
    this.onCheckPermission,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        // 请求权限按钮
        ElevatedButton.icon(
          onPressed: isLoading ? null : onRequestPermission,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: const Icon(Icons.lock_open),
          label: const Text('请求权限'),
        ),
        // 检查权限状态按钮
        ElevatedButton.icon(
          onPressed: isLoading ? null : onCheckPermission,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: const Icon(Icons.info_outline),
          label: const Text('检查权限状态'),
        ),
        // 打开系统设置按钮
        ElevatedButton.icon(
          onPressed: isLoading ? null : onOpenSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: const Icon(Icons.settings),
          label: const Text('打开系统设置'),
        ),
      ],
    );
  }
}

