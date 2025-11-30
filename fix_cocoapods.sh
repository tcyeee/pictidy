#!/bin/bash

echo "正在修复 CocoaPods 问题..."

# 检查 CocoaPods 版本
echo "当前 CocoaPods 版本:"
pod --version

# 尝试更新 CocoaPods
echo ""
echo "尝试更新 CocoaPods..."
sudo gem install cocoapods

# 如果使用 Homebrew，也可以尝试
# brew install cocoapods

# 清理并重新安装 pods
echo ""
echo "清理旧的 Pods..."
cd macos
rm -rf Pods Podfile.lock
cd ..

echo ""
echo "清理 Flutter 构建缓存..."
flutter clean

echo ""
echo "重新获取依赖..."
flutter pub get

echo ""
echo "重新安装 Pods..."
cd macos
pod install --repo-update
cd ..

echo ""
echo "完成！现在可以尝试运行: flutter run -d macos"

