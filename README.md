[中文](i18n/README.zh.md) | [English](README.md)

# PicTidy

PicTidy is a simple and efficient desktop album cleanup tool that helps you organize and manage your photos and videos.

## Features

- 📸 **Media Browsing**: Display photos and videos from folders one by one
- 🗑️ **Delete Functionality**: Quickly delete unwanted media files
- ⭐ **Favorite Management**: Mark your favorite photos and videos
- 📁 **Album Management**: Organize media files into different albums
- ⌨️ **Keyboard Shortcuts**: All operations support keyboard shortcuts for improved efficiency
- 💡 **Operation Hints**: Clear keyboard shortcut hints and operation feedback

## Keyboard Shortcuts

- `←` or `A`: Previous
- `→` or `D`: Next
- `Delete` or `Backspace`: Delete current media
- `F`: Toggle favorite status
- `S`: Add to album

## Usage

1. After launching the application, click the "Select Folder" button or use the menu to select a folder containing photos/videos
2. The app will automatically scan and load all media files
3. Use keyboard shortcuts or buttons to perform the following operations:
   - Browse photos/videos (left/right arrows or A/D keys)
   - Delete unwanted files (Delete key)
   - Favorite liked media (F key)
   - Add to album (S key)

## System Requirements

- Flutter SDK >= 3.0.0
- Supports macOS, Windows, and Linux desktop platforms

## Installation and Running

```bash
# Install dependencies
flutter pub get

# Run application (macOS)
flutter run -d macos

# Run application (Windows)
flutter run -d windows

# Run application (Linux)
flutter run -d linux
```

## Tech Stack

- Flutter - Cross-platform UI framework
- file_picker - Folder selection
- video_player - Video playback
- shared_preferences - Data persistence

## License

See LICENSE file for details

