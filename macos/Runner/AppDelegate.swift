import Cocoa
import FlutterMacOS
import Photos

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    
    // 注册平台通道
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      print("无法获取 FlutterViewController")
      return
    }
    
    let permissionChannel = FlutterMethodChannel(
      name: "com.pictidy/permissions",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    permissionChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "requestPhotoLibraryPermission" || call.method == "checkPhotoLibraryPermission" || call.method == "openSystemPreferences" || call.method == "getFirstPhoto" else {
        result(FlutterMethodNotImplemented)
        return
      }
      
      if call.method == "requestPhotoLibraryPermission" {
        self?.requestPhotoLibraryPermission(result: result)
      } else if call.method == "checkPhotoLibraryPermission" {
        self?.checkPhotoLibraryPermission(result: result)
      } else if call.method == "openSystemPreferences" {
        self?.openSystemPreferences(result: result)
      } else if call.method == "getFirstPhoto" {
        self?.getFirstPhoto(result: result)
      }
    }
  }

  private func requestPhotoLibraryPermission(result: @escaping FlutterResult) {
    if #available(macOS 11.0, *) {
      DispatchQueue.main.async {
        // 确保应用窗口是关键窗口并激活应用
        if let window = self.mainFlutterWindow {
          window.makeKeyAndOrderFront(nil)
          NSApp.activate(ignoringOtherApps: true)
        }
        
        // 先检查当前状态
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        print("📸 当前照片库权限状态: \(currentStatus.rawValue)")
        
        if currentStatus == .authorized || currentStatus == .limited {
          print("✅ 照片库权限已授予")
          result(true)
          return
        }
        
        if currentStatus == .denied || currentStatus == .restricted {
          print("❌ 照片库权限被拒绝或受限，需要用户在系统设置中手动开启")
          result(false)
          return
        }
        
        // 状态为 .notDetermined，请求权限
        print("🔔 请求照片库权限（将弹出系统对话框）...")
        
        // 在 macOS 上，直接调用 requestAuthorization 应该会弹出系统权限对话框
        // 确保应用在前台，这样用户能看到对话框
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
          DispatchQueue.main.async {
            let granted = (newStatus == .authorized || newStatus == .limited)
            print("📸 权限请求结果: \(newStatus.rawValue), 授予: \(granted)")
            
            // 如果用户授予了权限，再次确认窗口在前台
            if granted {
              if let window = self.mainFlutterWindow {
                window.makeKeyAndOrderFront(nil)
              }
            }
            
            result(granted)
          }
        }
      }
    } else {
      // macOS 10.14 及更早版本不支持 PHPhotoLibrary API
      print("⚠️ macOS 版本过低，不支持照片库权限 API")
      result(false)
    }
  }

  private func checkPhotoLibraryPermission(result: @escaping FlutterResult) {
    if #available(macOS 11.0, *) {
      let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
      let hasPermission = (status == .authorized || status == .limited)
      print("🔍 检查照片库权限: \(status.rawValue), 有权限: \(hasPermission)")
      result(hasPermission)
    } else {
      // macOS 10.14 及更早版本不支持 PHPhotoLibrary API
      result(false)
    }
  }

  private func openSystemPreferences(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      // macOS 13+ 使用新的系统设置 URL
      if #available(macOS 13.0, *) {
        // macOS 13+ 使用新的 Settings URL scheme
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos") {
          NSWorkspace.shared.open(url)
        } else if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
          NSWorkspace.shared.open(url)
        }
      } else {
        // macOS 12 及更早版本
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos") {
          NSWorkspace.shared.open(url)
        }
      }
      result(nil)
    }
  }

  private func getFirstPhoto(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      if #available(macOS 11.0, *) {
        // 确保应用窗口是关键窗口
        if let window = self.mainFlutterWindow {
          window.makeKeyAndOrderFront(nil)
          NSApp.activate(ignoringOtherApps: true)
        }
        
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        // 如果权限未授予，先尝试请求权限
        // 直接尝试访问照片库资源，系统会自动弹出权限对话框
        if status == .notDetermined {
          print("🔔 权限未确定，尝试访问照片库以触发权限对话框...")
          // 直接尝试获取照片资源，这会触发系统权限对话框
          let fetchOptions = PHFetchOptions()
          fetchOptions.fetchLimit = 1
          _ = PHAsset.fetchAssets(with: .image, options: fetchOptions)
          
          // 然后请求权限
          PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
            DispatchQueue.main.async {
              if newStatus == .authorized || newStatus == .limited {
                // 权限已授予，继续获取照片
                self._fetchFirstPhoto(result: result)
              } else {
                result(FlutterError(code: "PERMISSION_DENIED", message: "照片库权限未授予", details: nil))
              }
            }
          }
          return
        }
        
        guard status == .authorized || status == .limited else {
          result(FlutterError(code: "PERMISSION_DENIED", message: "照片库权限未授予", details: nil))
          return
        }
        
        self._fetchFirstPhoto(result: result)
      } else {
        result(FlutterError(code: "UNSUPPORTED", message: "macOS 11.0+ 才支持此功能", details: nil))
      }
    }
  }
  
  private func _fetchFirstPhoto(result: @escaping FlutterResult) {
    if #available(macOS 11.0, *) {
      // 获取所有照片资源
      let fetchOptions = PHFetchOptions()
      fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      fetchOptions.fetchLimit = 1
      
      let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
      
      guard assets.count > 0 else {
        result(FlutterError(code: "NO_PHOTOS", message: "照片库中没有照片", details: nil))
        return
      }
      
      let asset = assets.object(at: 0)
      
      // 请求图片数据
      let options = PHImageRequestOptions()
      options.deliveryMode = .highQualityFormat
      options.isSynchronous = false
      options.isNetworkAccessAllowed = true
      
      PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { imageData, dataUTI, orientation, info in
        DispatchQueue.main.async {
          guard let imageData = imageData else {
            result(FlutterError(code: "IMAGE_LOAD_FAILED", message: "无法加载图片数据", details: nil))
            return
          }
          
          // 保存到临时文件
          let tempDir = FileManager.default.temporaryDirectory
          let fileName = "\(asset.localIdentifier.replacingOccurrences(of: "/", with: "_")).jpg"
          let fileURL = tempDir.appendingPathComponent(fileName)
          
          do {
            try imageData.write(to: fileURL)
            
            // 返回图片信息
            let photoInfo: [String: Any] = [
              "path": fileURL.path,
              "localIdentifier": asset.localIdentifier,
              "creationDate": asset.creationDate?.timeIntervalSince1970 ?? 0,
              "width": asset.pixelWidth,
              "height": asset.pixelHeight,
            ]
            
            result(photoInfo)
          } catch {
            result(FlutterError(code: "FILE_WRITE_FAILED", message: "无法保存图片文件: \(error.localizedDescription)", details: nil))
          }
        }
      }
    } else {
      result(FlutterError(code: "UNSUPPORTED", message: "macOS 11.0+ 才支持此功能", details: nil))
    }
  }
}
