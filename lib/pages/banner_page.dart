import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../main.dart' show MyHomePage;

/// 启动页（Banner页）
///
/// 显示应用名称，并在后台检查并请求相册访问权限
/// 权限获取成功后自动导航到主页面
class BannerPage extends StatefulWidget {
  const BannerPage({super.key});

  @override
  State<BannerPage> createState() => _BannerPageState();
}

class _BannerPageState extends State<BannerPage> {
  final PermissionService _permissionService = PermissionService();
  String _statusMessage = '正在检查权限...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 延迟一小段时间后开始检查权限，让用户看到启动页
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkAndRequestPermission();
    });
  }

  /// 检查并请求权限
  ///
  /// 先检查当前权限状态，如果没有权限则请求权限
  /// 权限获取成功后导航到主页面
  Future<void> _checkAndRequestPermission() async {
    try {
      // 步骤1: 检查当前权限状态
      setState(() {
        _statusMessage = '正在检查权限状态...';
      });

      final state = await _permissionService.checkPermissionStatus();

      // 步骤2: 判断是否有权限
      if (_permissionService.hasPermission(state)) {
        // 已有权限，直接进入主页面
        setState(() {
          _statusMessage = '权限已授予，正在进入应用...';
        });
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToHome();
      } else {
        // 没有权限，请求权限
        setState(() {
          _statusMessage = '正在请求相册访问权限...';
        });

        final requestState = await _permissionService.requestPermission();

        if (_permissionService.hasPermission(requestState)) {
          // 权限已授予
          setState(() {
            _statusMessage = '权限已授予，正在进入应用...';
          });
          await Future.delayed(const Duration(milliseconds: 500));
          _navigateToHome();
        } else {
          // 权限被拒绝，提示用户
          setState(() {
            _isLoading = false;
            _statusMessage = '需要相册访问权限才能使用应用\n\n请点击下方按钮打开系统设置授权';
          });
        }
      }
    } catch (e) {
      // 如果权限检查失败，尝试直接请求权限
      try {
        setState(() {
          _statusMessage = '正在请求相册访问权限...';
        });

        final requestState = await _permissionService.requestPermission();
        if (_permissionService.hasPermission(requestState)) {
          setState(() {
            _statusMessage = '权限已授予，正在进入应用...';
          });
          await Future.delayed(const Duration(milliseconds: 500));
          _navigateToHome();
        } else {
          setState(() {
            _isLoading = false;
            _statusMessage = '需要相册访问权限才能使用应用\n\n请点击下方按钮打开系统设置授权';
          });
        }
      } catch (requestError) {
        setState(() {
          _isLoading = false;
          _statusMessage = '权限请求失败: $requestError\n\n请点击下方按钮打开系统设置手动授权';
        });
      }
    }
  }

  /// 导航到主页面
  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MyHomePage(),
        ),
      );
    }
  }

  /// 打开系统设置
  Future<void> _openSystemSettings() async {
    try {
      await _permissionService.openSystemSettings();
      // 等待用户返回应用后重新检查权限
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _isLoading = true;
        _statusMessage = '正在重新检查权限...';
      });
      await _checkAndRequestPermission();
    } catch (e) {
      setState(() {
        _statusMessage = '无法打开系统设置: $e\n\n请手动打开: 系统设置 > 隐私与安全性 > 照片';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple[400]!,
              Colors.deepPurple[600]!,
              Colors.deepPurple[800]!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 应用名称
              const Text(
                'PicTidy',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 40),
              // 状态信息
              if (_isLoading)
                Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _openSystemSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('打开系统设置'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _checkAndRequestPermission,
                      child: const Text(
                        '重试',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

