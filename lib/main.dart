import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'services/permission_service.dart';
import 'services/photo_service.dart';
import 'widgets/photo_preview.dart';
import 'widgets/photo_thumbnail_grid.dart';
import 'widgets/photo_info_panel.dart';

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
  String? _previewImagePath;
  Uint8List? _previewImageData;
  AssetEntity? _selectedAsset;
  bool _isLoading = false;
  bool _isLoadingPreview = false;
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
          _previewImagePath = result.filePath;
          _previewImageData = result.imageData;
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

  /// 处理照片选择
  ///
  /// 当用户点击缩略图时调用，加载选中照片的完整数据
  Future<void> _onPhotoSelected(AssetEntity asset) async {
    setState(() {
      _selectedAsset = asset;
      _isLoadingPreview = true;
      _previewImagePath = null;
      _previewImageData = null;
    });

    try {
      final result = await _photoService.loadPhotoData(asset);
      if (result.success && result.hasData) {
        setState(() {
          _previewImagePath = result.filePath;
          _previewImageData = result.imageData;
          _isLoadingPreview = false;
        });
      } else {
        setState(() {
          _isLoadingPreview = false;
        });
        _updateDebugInfo('加载照片失败: ${result.errorMessage}');
      }
    } catch (e) {
      setState(() {
        _isLoadingPreview = false;
      });
      _updateDebugInfo('加载照片时出错: $e');
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Pic Tidy'),
        actions: [
          // 权限相关按钮移到AppBar
          IconButton(
            icon: const Icon(Icons.lock_open),
            tooltip: '请求权限',
            onPressed: _isLoading ? null : _requestPermission,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '检查权限',
            onPressed: _isLoading ? null : _checkPermissionStatus,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '系统设置',
            onPressed: _isLoading ? null : _openSystemSettings,
          ),
        ],
      ),
      body: Row(
        children: [
          // 左侧面板
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // 上半部分：照片缩略图网格
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('照片缩略图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: PhotoThumbnailGrid(onPhotoSelected: _onPhotoSelected)),
                      ],
                    ),
                  ),
                ),
                // 分隔线
                const Divider(height: 1),
                // 下半部分：照片信息面板
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('照片信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: PhotoInfoPanel(asset: _selectedAsset)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 右侧主区域：照片预览
          Expanded(
            child: PhotoPreview(
              imagePath: _previewImagePath,
              imageData: _previewImageData,
              isLoading: _isLoadingPreview,
            ),
          ),
        ],
      ),
      // 底部调试信息（可选，可以通过浮动按钮或抽屉显示）
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('调试信息'),
                  content: SingleChildScrollView(
                    child: Text(_debugInfo, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  ),
                  actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('关闭'))],
                ),
          );
        },
        child: const Icon(Icons.bug_report),
      ),
    );
  }
}
