import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// 权限状态枚举
enum PhotoLibraryPermissionStatus {
  notDetermined,  // 未决定
  restricted,     // 受限
  denied,         // 拒绝
  authorized,     // 已授权
  limited,        // 有限访问（iOS 14+）
}

/// 权限服务
class PermissionService {
  static const MethodChannel _channel = MethodChannel('com.pictidy/permissions');

  /// 请求照片库权限
  /// 返回 true 表示已授权，false 表示被拒绝
  static Future<bool> requestPhotoLibraryPermission() async {
    try {
      if (defaultTargetPlatform != TargetPlatform.macOS) {
        debugPrint('权限请求仅在 macOS 上支持');
        return false;
      }

      debugPrint('🔔 开始请求照片库权限...');
      final result = await _channel.invokeMethod<bool>('requestPhotoLibraryPermission');
      final granted = result ?? false;
      debugPrint('📸 权限请求结果: $granted');
      return granted;
    } catch (e) {
      debugPrint('❌ 请求照片库权限失败: $e');
      return false;
    }
  }

  /// 检查照片库权限状态
  /// 返回 true 表示已授权，false 表示未授权
  static Future<bool> checkPhotoLibraryPermission() async {
    try {
      if (defaultTargetPlatform != TargetPlatform.macOS) {
        debugPrint('权限检查仅在 macOS 上支持');
        return false;
      }

      final result = await _channel.invokeMethod<bool>('checkPhotoLibraryPermission');
      final hasPermission = result ?? false;
      debugPrint('🔍 照片库权限状态: $hasPermission');
      return hasPermission;
    } catch (e) {
      debugPrint('❌ 检查照片库权限失败: $e');
      return false;
    }
  }

  /// 打开系统设置中的权限页面
  static Future<void> openSystemPreferences() async {
    try {
      if (defaultTargetPlatform != TargetPlatform.macOS) {
        return;
      }
      await _channel.invokeMethod('openSystemPreferences');
    } catch (e) {
      debugPrint('打开系统设置失败: $e');
    }
  }

  /// 获取照片库中的第一张照片
  /// 返回包含照片路径和信息的 Map，如果失败返回 null
  static Future<Map<String, dynamic>?> getFirstPhoto() async {
    try {
      if (defaultTargetPlatform != TargetPlatform.macOS) {
        debugPrint('获取照片仅在 macOS 上支持');
        return null;
      }

      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getFirstPhoto');
      if (result == null) {
        return null;
      }
      
      // 转换类型
      return Map<String, dynamic>.from(result);
    } catch (e) {
      debugPrint('获取第一张照片失败: $e');
      return null;
    }
  }
}

