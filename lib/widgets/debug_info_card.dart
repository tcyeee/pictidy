import 'package:flutter/material.dart';

/// 调试信息卡片组件
/// 
/// 用于显示应用运行时的调试信息，帮助用户了解当前状态
class DebugInfoCard extends StatelessWidget {
  /// 要显示的调试信息文本
  final String debugInfo;

  const DebugInfoCard({
    super.key,
    required this.debugInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '调试信息',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              debugInfo,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

