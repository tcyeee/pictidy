import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'services/permission_service.dart';
import 'services/photo_service.dart';
import 'widgets/debug_info_card.dart';
import 'widgets/action_buttons.dart';
import 'widgets/photo_display_card.dart';

/// 应用程序入口
void main() {
  runApp(const MyApp());
}

/// 主应用组件
///
/// 配置应用主题和路由
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pic Tidy',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      home: const MyHomePage(),
    );
  }
}

/// 主页面组件
///
/// 负责管理权限检查和照片加载的UI界面
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// 主页面状态类
///
/// 管理页面状态，包括：
/// - 权限状态
/// - 照片数据
/// - 加载状态
/// - 调试信息
class _MyHomePageState extends State<MyHomePage> {
  // 服务实例
  final PermissionService _permissionService = PermissionService();
  final PhotoService _photoService = PhotoService();

  // 状态变量
  String? _firstImagePath;
  Uint8List? _firstImageData;
  bool _isLoading = false;
  String _debugInfo = '正在初始化...';

  @override
  void initState() {
    super.initState();
    // 启动时自动检查权限并加载照片
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadPhoto();
    });
  }

  /// 检查权限并加载照片
  ///
  /// 启动时自动调用，先检查权限状态，如果有权限则加载照片
  /// 在 macOS 上，即使权限检查显示未授权，也可能实际已授权，所以会尝试直接加载
  Future<void> _checkAndLoadPhoto() async {
    setState(() {
      _isLoading = true;
      _debugInfo = '正在检查权限状态...';
    });

    try {
      // 检查当前权限状态
      final state = await _permissionService.checkPermissionStatus();
      final statusText = _permissionService.formatPermissionStatus(state);
      _updateDebugInfo('权限状态: $statusText');

      // 判断是否有权限
      if (_permissionService.hasPermission(state)) {
        // 权限状态显示已授予，直接加载照片
        _updateDebugInfo('权限状态显示已授予，正在加载照片...');
        await _loadFirstPhoto();
      } else {
        // 尝试直接加载照片，因为 macOS 的权限检查可能不准确
        _updateDebugInfo('权限状态显示未授予，但尝试直接访问照片...');
        try {
          await _loadFirstPhoto();
        } catch (e) {
          // 如果访问失败，说明真的没有权限
          setState(() {
            _isLoading = false;
            _debugInfo = '无法访问照片\n请点击"请求权限"按钮';
          });
        }
      }
    } catch (e) {
      // 如果权限检查失败，也尝试直接加载照片
      _updateDebugInfo('权限检查失败，尝试直接访问照片...');
      try {
        await _loadFirstPhoto();
      } catch (loadError) {
        setState(() {
          _isLoading = false;
          _debugInfo = '检查权限失败: $e\n访问照片也失败: $loadError';
        });
        debugPrint('检查权限错误: $e');
        debugPrint('访问照片错误: $loadError');
      }
    }
  }

  /// 检查权限状态
  ///
  /// 手动检查当前权限状态，并显示详细信息
  Future<void> _checkPermissionStatus() async {
    setState(() {
      _isLoading = true;
      _debugInfo = '正在检查权限状态...';
    });

    try {
      final state = await _permissionService.checkPermissionStatus();
      final statusText = _permissionService.formatPermissionStatus(state);

      setState(() {
        _isLoading = false;
        _debugInfo = statusText;
      });

      debugPrint('权限状态检查:');
      debugPrint('  完整状态: $state');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugInfo = '检查权限状态失败: $e';
      });
      debugPrint('检查权限状态错误: $e');
    }
  }

  /// 请求照片访问权限
  ///
  /// 弹出系统权限对话框，请求用户授权
  /// 如果授权成功，会自动加载照片
  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _debugInfo = '正在请求权限...\n请在弹出的对话框中点击"好"或"允许"';
    });

    try {
      final state = await _permissionService.requestPermission();
      final statusText = _permissionService.formatPermissionStatus(state);

      debugPrint('权限请求结果:');
      debugPrint('  完整状态: $state');

      if (_permissionService.hasPermission(state)) {
        setState(() {
          _isLoading = false;
          _debugInfo = '✅ 权限已授予！\n$statusText';
        });
        // 权限已授予，加载照片
        await _loadFirstPhoto();
      } else {
        setState(() {
          _isLoading = false;
          _debugInfo =
              '❌ 权限被拒绝\n$statusText\n\n'
              '请点击"打开系统设置"按钮手动授权';
        });
      }
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
        _debugInfo = '❌ 请求权限时出错: $e';
      });
      debugPrint('请求权限错误: $e');
      debugPrint('堆栈: $stackTrace');
    }
  }

  /// 打开系统设置页面
  ///
  /// 引导用户到系统设置中手动授权照片访问权限
  Future<void> _openSystemSettings() async {
    try {
      await _permissionService.openSystemSettings();
      setState(() {
        _debugInfo =
            '已打开系统设置\n'
            '请在"隐私与安全性" > "照片"中找到应用并授权\n'
            '授权后点击"检查权限状态"按钮';
      });
    } catch (e) {
      setState(() {
        _debugInfo =
            '无法打开系统设置: $e\n'
            '请手动打开: 系统设置 > 隐私与安全性 > 照片';
      });
      debugPrint('打开系统设置失败: $e');
    }
  }

  /// 加载第一张照片
  ///
  /// 从相册中加载第一张照片，并更新UI显示
  Future<void> _loadFirstPhoto() async {
    try {
      setState(() {
        _isLoading = true;
        _debugInfo = '正在获取相册列表...';
      });

      // 使用照片服务加载照片
      final result = await _photoService.loadFirstPhoto();

      if (result.success && result.hasData) {
        // 加载成功
        _updateDebugInfo(
          result.filePath != null ? '✅ 成功！文件路径: ${result.filePath}' : '✅ 成功！数据大小: ${result.imageData!.length} 字节',
        );
        setState(() {
          _firstImagePath = result.filePath;
          _firstImageData = result.imageData;
          _isLoading = false;
        });
      } else {
        // 加载失败
        _updateDebugInfo(result.errorMessage ?? '❌ 所有方法都失败了！无法获取照片数据');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      _updateDebugInfo('❌ 加载照片时出错: $e');
      debugPrint('完整错误: $e');
      debugPrint('堆栈: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 更新调试信息
  ///
  /// 同时更新状态和打印日志
  void _updateDebugInfo(String info) {
    debugPrint(info);
    setState(() {
      _debugInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: const Text('Pic Tidy')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 调试信息卡片
              DebugInfoCard(debugInfo: _debugInfo),
              const SizedBox(height: 20),
              // 操作按钮组
              ActionButtons(
                isLoading: _isLoading,
                onRequestPermission: _requestPermission,
                onCheckPermission: _checkPermissionStatus,
                onOpenSettings: _openSystemSettings,
              ),
              // 加载指示器
              if (_isLoading) ...[const SizedBox(height: 20), const Center(child: CircularProgressIndicator())],
              const SizedBox(height: 20),
              // 照片显示卡片
              PhotoDisplayCard(imagePath: _firstImagePath, imageData: _firstImageData),
            ],
          ),
        ),
      ),
    );
  }
}
