# 故障排除指南

## CocoaPods 问题

如果遇到 CocoaPods 相关的错误（特别是 Ruby/ffi 兼容性问题），请尝试以下解决方案：

### 方案 1: 更新 CocoaPods（推荐）

```bash
sudo gem install cocoapods
```

### 方案 2: 使用 Homebrew 安装 CocoaPods

```bash
brew install cocoapods
```

### 方案 3: 如果仍然有问题，尝试清理并重新安装

```bash
cd macos
rm -rf Pods Podfile.lock
cd ..
flutter clean
flutter pub get
cd macos
pod install --repo-update
```

## 运行项目

### macOS

```bash
flutter run -d macos
```

### Windows

```bash
flutter run -d windows
```

### Linux

```bash
flutter run -d linux
```

## 常见问题

### 1. file_picker 权限问题

如果文件选择器无法正常工作，请检查：
- macOS: 确保应用有文件访问权限（系统设置 > 隐私与安全性 > 文件和文件夹）
- Windows: 确保应用有文件系统访问权限

### 2. 视频播放问题

如果视频无法播放，请确保：
- 已安装必要的视频编解码器
- 视频格式受支持（mp4, mov, avi 等）

### 3. 快捷键不响应

确保应用窗口已获得焦点，快捷键才会生效。

