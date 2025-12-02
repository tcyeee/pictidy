import 'package:photo_manager/photo_manager.dart';

/// 权限管理服务类
/// 负责处理照片访问权限的检查、请求和系统设置打开等功能
class PermissionService {
  /// 单例实例
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// 当前权限状态
  PermissionState? _currentPermissionState;

  /// 获取当前权限状态
  PermissionState? get currentPermissionState => _currentPermissionState;

  /// 检查权限状态
  ///
  /// 返回权限状态对象，包含 isAuth、isLimited、hasAccess 等信息
  /// 如果检查失败会抛出异常
  Future<PermissionState> checkPermissionStatus() async {
    try {
      final state = await PhotoManager.requestPermissionExtend();
      _currentPermissionState = state;
      return state;
    } catch (e) {
      throw Exception('检查权限状态失败: $e');
    }
  }

  /// 请求照片访问权限
  ///
  /// 会弹出系统权限对话框，用户需要手动授权
  /// 返回权限状态对象
  Future<PermissionState> requestPermission() async {
    try {
      final state = await PhotoManager.requestPermissionExtend();
      _currentPermissionState = state;
      return state;
    } catch (e) {
      throw Exception('请求权限失败: $e');
    }
  }

  /// 判断是否有权限访问照片
  ///
  /// 在 macOS 上，即使 isAuth 为 false，也可能权限已授予（系统设置中显示已授权）
  /// 所以需要同时检查多个条件
  bool hasPermission(PermissionState state) {
    return state.isAuth || state.isLimited || state.hasAccess;
  }

  /// 格式化权限状态信息为字符串
  ///
  /// 用于调试和显示给用户
  String formatPermissionStatus(PermissionState state) {
    return '权限状态:\n'
        'isAuth: ${state.isAuth}\n'
        'isLimited: ${state.isLimited}\n'
        'hasAccess: ${state.hasAccess}\n'
        '状态: ${state.toString()}';
  }

  /// 打开系统设置页面
  ///
  /// 引导用户到系统设置中手动授权照片访问权限
  /// 在 macOS 上会打开"隐私与安全性" > "照片"设置页面
  Future<void> openSystemSettings() async {
    try {
      await PhotoManager.openSetting();
    } catch (e) {
      throw Exception('无法打开系统设置: $e');
    }
  }
}
