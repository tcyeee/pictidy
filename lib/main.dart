import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'pages/banner_page.dart';
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
      home: const BannerPage(), // 启动页作为首页
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
  final PhotoService _photoService = PhotoService();

  // 状态变量
  String? _previewImagePath;
  Uint8List? _previewImageData;
  AssetEntity? _selectedAsset;
  bool _isLoadingPreview = false;
  String _debugInfo = '已进入主界面';

  @override
  void initState() {
    super.initState();
    // 页面加载后自动加载照片缩略图
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPhotos();
    });
  }

  /// 加载照片
  ///
  /// 页面加载后自动调用，加载最近的20张照片
  Future<void> _loadPhotos() async {
    // 照片缩略图会在 PhotoThumbnailGrid 组件中自动加载
    // 这里可以做一些初始化工作
    setState(() {
      _debugInfo = '已进入主界面';
    });
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
