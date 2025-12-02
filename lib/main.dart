import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pic Tidy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _firstImagePath;
  Uint8List? _firstImageData;
  bool _isLoading = false;
  String _debugInfo = '正在初始化...';
  PermissionState? _currentPermissionState;

  @override
  void initState() {
    super.initState();
    // 启动时自动检查权限并加载照片
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadPhoto();
    });
  }

  Future<void> _checkAndLoadPhoto() async {
    setState(() {
      _isLoading = true;
      _debugInfo = '正在检查权限状态...';
    });

    try {
      // 检查当前权限状态
      final PermissionState state = await PhotoManager.requestPermissionExtend();
      _currentPermissionState = state;
      
      _updateDebugInfo('权限状态: isAuth=${state.isAuth}, isLimited=${state.isLimited}, hasAccess=${state.hasAccess}');
      
      // 在 macOS 上，即使 isAuth 为 false，也可能权限已授予（系统设置中显示已授权）
      // 所以直接尝试加载照片，如果失败再提示用户
      if (state.isAuth || state.isLimited || state.hasAccess) {
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

  Future<void> _checkPermissionStatus() async {
    setState(() {
      _isLoading = true;
      _debugInfo = '正在检查权限状态...';
    });

    try {
      final PermissionState state = await PhotoManager.requestPermissionExtend();
      _currentPermissionState = state;
      
      setState(() {
        _isLoading = false;
        _debugInfo = '权限状态:\n'
            'isAuth: ${state.isAuth}\n'
            'isLimited: ${state.isLimited}\n'
            'hasAccess: ${state.hasAccess}\n'
            '状态: ${state.toString()}';
      });
      
      debugPrint('权限状态检查:');
      debugPrint('  isAuth: ${state.isAuth}');
      debugPrint('  isLimited: ${state.isLimited}');
      debugPrint('  hasAccess: ${state.hasAccess}');
      debugPrint('  完整状态: $state');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugInfo = '检查权限状态失败: $e';
      });
      debugPrint('检查权限状态错误: $e');
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _debugInfo = '正在请求权限...\n请在弹出的对话框中点击"好"或"允许"';
    });

    try {
      // 明确请求权限
      final PermissionState state = await PhotoManager.requestPermissionExtend();
      _currentPermissionState = state;
      
      debugPrint('权限请求结果:');
      debugPrint('  isAuth: ${state.isAuth}');
      debugPrint('  isLimited: ${state.isLimited}');
      debugPrint('  hasAccess: ${state.hasAccess}');
      
      if (state.isAuth || state.isLimited) {
        setState(() {
          _isLoading = false;
          _debugInfo = '✅ 权限已授予！\n'
              'isAuth: ${state.isAuth}\n'
              'isLimited: ${state.isLimited}';
        });
        // 权限已授予，加载照片
        await _loadFirstPhoto();
      } else {
        setState(() {
          _isLoading = false;
          _debugInfo = '❌ 权限被拒绝\n'
              'isAuth: ${state.isAuth}\n'
              'isLimited: ${state.isLimited}\n'
              'hasAccess: ${state.hasAccess}\n\n'
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

  Future<void> _openSystemSettings() async {
    try {
      await PhotoManager.openSetting();
      setState(() {
        _debugInfo = '已打开系统设置\n'
            '请在"隐私与安全性" > "照片"中找到应用并授权\n'
            '授权后点击"检查权限状态"按钮';
      });
    } catch (e) {
      setState(() {
        _debugInfo = '无法打开系统设置: $e\n'
            '请手动打开: 系统设置 > 隐私与安全性 > 照片';
      });
      debugPrint('打开系统设置失败: $e');
    }
  }

  Future<void> _loadFirstPhoto() async {
    try {
      setState(() {
        _isLoading = true;
        _debugInfo = '正在获取相册列表...';
      });

      // 直接尝试获取相册列表，如果失败会抛出异常
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('获取相册列表超时');
        },
      );
      
      _updateDebugInfo('找到 ${paths.length} 个相册');

      if (paths.isEmpty) {
        _updateDebugInfo('❌ 未找到任何相册');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final AssetPathEntity firstPath = paths.first;
      _updateDebugInfo('正在从相册"${firstPath.name}"获取照片...');
      
      final List<AssetEntity> assets = await firstPath.getAssetListPaged(
        page: 0,
        size: 1,
      );
      _updateDebugInfo('获取到 ${assets.length} 张照片');

      if (assets.isEmpty) {
        _updateDebugInfo('❌ 相册中没有照片');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final AssetEntity firstAsset = assets.first;
      _updateDebugInfo('正在获取照片数据...');
      
      // 方法1: 尝试获取文件
      try {
        final file = await firstAsset.originFile;
        if (file != null) {
          _updateDebugInfo('✅ 成功！文件路径: ${file.path}');
          setState(() {
            _firstImagePath = file.path;
            _firstImageData = null;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        _updateDebugInfo('originFile 失败: $e');
      }

      // 方法2: 尝试获取图片数据
      try {
        final imageData = await firstAsset.originBytes;
        if (imageData != null && imageData.isNotEmpty) {
          _updateDebugInfo('✅ 成功！数据大小: ${imageData.length} 字节');
          setState(() {
            _firstImagePath = null;
            _firstImageData = imageData;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        _updateDebugInfo('originBytes 失败: $e');
      }

      // 方法3: 尝试 file
      try {
        final file = await firstAsset.file;
        if (file != null) {
          _updateDebugInfo('✅ 成功！文件路径: ${file.path}');
          setState(() {
            _firstImagePath = file.path;
            _firstImageData = null;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        _updateDebugInfo('file 失败: $e');
      }

      // 方法4: 尝试缩略图
      try {
        final thumbnailData = await firstAsset.thumbnailData;
        if (thumbnailData != null && thumbnailData.isNotEmpty) {
          _updateDebugInfo('✅ 成功！缩略图大小: ${thumbnailData.length} 字节');
          setState(() {
            _firstImagePath = null;
            _firstImageData = thumbnailData;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        _updateDebugInfo('thumbnailData 失败: $e');
      }

      _updateDebugInfo('❌ 所有方法都失败了！无法获取照片数据');
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      _updateDebugInfo('❌ 加载照片时出错: $e');
      debugPrint('完整错误: $e');
      debugPrint('堆栈: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 调试信息
              Card(
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
                        _debugInfo,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 按钮组
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _requestPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.lock_open),
                    label: const Text('请求权限'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkPermissionStatus,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('检查权限状态'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _openSystemSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.settings),
                    label: const Text('打开系统设置'),
                  ),
                ],
              ),
              if (_isLoading) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
              ],
              const SizedBox(height: 20),
              // 图片显示
              if (_firstImagePath != null || _firstImageData != null)
                Card(
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
                        _firstImagePath != null
                            ? Image.file(
                                File(_firstImagePath!),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text('加载失败: $error');
                                },
                              )
                            : Image.memory(
                                _firstImageData!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text('加载失败: $error');
                                },
                              ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
