import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pictidy/models/media_item.dart';
import 'package:pictidy/services/media_service.dart';
import 'package:pictidy/services/favorite_service.dart';
import 'package:pictidy/services/album_service.dart';
import 'package:pictidy/widgets/media_viewer.dart';
import 'package:pictidy/widgets/shortcut_hint.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Intent classes for shortcuts
class _NextMediaIntent extends Intent {
  const _NextMediaIntent();
}

class _PreviousMediaIntent extends Intent {
  const _PreviousMediaIntent();
}

class _DeleteMediaIntent extends Intent {
  const _DeleteMediaIntent();
}

class _ToggleFavoriteIntent extends Intent {
  const _ToggleFavoriteIntent();
}

class _AddToAlbumIntent extends Intent {
  const _AddToAlbumIntent();
}

class HomeScreen extends StatefulWidget {
  final Function(Locale)? onLocaleChanged;
  
  const HomeScreen({super.key, this.onLocaleChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MediaItem> _mediaItems = [];
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectDirectory() async {
    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null && mounted) {
        setState(() {
          _isLoading = true;
        });

        final mediaItems = await MediaService.loadMediaFromDirectory(selectedDirectory);
        
        // 加载收藏状态和相册信息
        for (var i = 0; i < mediaItems.length; i++) {
          final item = mediaItems[i];
          final isFav = await FavoriteService.isFavorite(item.path);
          final albumName = await AlbumService.getAlbumForMedia(item.path);
          if (isFav || albumName != null) {
            mediaItems[i] = MediaItem(
              file: item.file,
              isVideo: item.isVideo,
              isFavorite: isFav,
              albumName: albumName,
              dateModified: item.dateModified,
            );
          }
        }

        if (mounted) {
          setState(() {
            _mediaItems = mediaItems;
            _currentIndex = 0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(l10n.selectFolderFailed(e.toString()), Colors.red);
      }
    }
  }

  Future<void> _deleteCurrent() async {
    if (_mediaItems.isEmpty || _currentIndex >= _mediaItems.length) return;
    if (!mounted) return;

    final item = _mediaItems[_currentIndex];
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteMessage(item.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await MediaService.deleteMedia(item);
      if (mounted) {
        if (success) {
          setState(() {
            _mediaItems.removeAt(_currentIndex);
            if (_currentIndex >= _mediaItems.length && _currentIndex > 0) {
              _currentIndex--;
            }
          });
          final l10n = AppLocalizations.of(context)!;
          _showSnackBar('${l10n.deleted}: ${item.name}', Colors.green);
        } else {
          final l10n = AppLocalizations.of(context)!;
          _showSnackBar(l10n.deleteFailed, Colors.red);
        }
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_mediaItems.isEmpty || _currentIndex >= _mediaItems.length) return;

    final item = _mediaItems[_currentIndex];
    await FavoriteService.toggleFavorite(item);
    
    final isFav = await FavoriteService.isFavorite(item.path);
    if (mounted) {
      setState(() {
        _mediaItems[_currentIndex] = MediaItem(
          file: item.file,
          isVideo: item.isVideo,
          isFavorite: isFav,
          albumName: item.albumName,
          dateModified: item.dateModified,
        );
      });
      
      final l10n = AppLocalizations.of(context)!;
      _showSnackBar(
        isFav ? l10n.addedToFavorites : l10n.removedFromFavorites,
        isFav ? Colors.amber : Colors.grey,
      );
    }
  }

  Future<void> _addToAlbum() async {
    if (_mediaItems.isEmpty || _currentIndex >= _mediaItems.length) return;
    if (!mounted) return;

    final item = _mediaItems[_currentIndex];
    final albumNames = await AlbumService.getAlbumNames();
    if (!mounted) return;
    
    String? selectedAlbum = await showDialog<String>(
      context: context,
      builder: (context) => _AlbumDialog(albumNames: albumNames),
    );

    if (selectedAlbum != null && mounted) {
      if (selectedAlbum == '_new_') {
        // 创建新相册
        final newAlbumName = await _showCreateAlbumDialog();
        if (newAlbumName != null && newAlbumName.isNotEmpty && mounted) {
          await AlbumService.createAlbum(newAlbumName);
          await AlbumService.addToAlbum(newAlbumName, item.path);
          if (mounted) {
            setState(() {
              _mediaItems[_currentIndex] = MediaItem(
                file: item.file,
                isVideo: item.isVideo,
                isFavorite: item.isFavorite,
                albumName: newAlbumName,
                dateModified: item.dateModified,
              );
            });
            final l10n = AppLocalizations.of(context)!;
            _showSnackBar(l10n.addedToAlbum(newAlbumName), Colors.blue);
          }
        }
      } else {
        await AlbumService.addToAlbum(selectedAlbum, item.path);
        if (mounted) {
          setState(() {
            _mediaItems[_currentIndex] = MediaItem(
              file: item.file,
              isVideo: item.isVideo,
              isFavorite: item.isFavorite,
              albumName: selectedAlbum,
              dateModified: item.dateModified,
            );
          });
          final l10n = AppLocalizations.of(context)!;
          _showSnackBar(l10n.addedToAlbum(selectedAlbum), Colors.blue);
        }
      }
    }
  }

  Future<String?> _showCreateAlbumDialog() async {
    if (!mounted) return null;
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createNewAlbum),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.albumName,
            hintText: l10n.enterAlbumName,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToNext() {
    if (_currentIndex < _mediaItems.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _navigateToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowRight): _NextMediaIntent(),
        SingleActivator(LogicalKeyboardKey.keyD): _NextMediaIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PreviousMediaIntent(),
        SingleActivator(LogicalKeyboardKey.keyA): _PreviousMediaIntent(),
        SingleActivator(LogicalKeyboardKey.delete): _DeleteMediaIntent(),
        SingleActivator(LogicalKeyboardKey.backspace): _DeleteMediaIntent(),
        SingleActivator(LogicalKeyboardKey.keyF): _ToggleFavoriteIntent(),
        SingleActivator(LogicalKeyboardKey.keyS): _AddToAlbumIntent(),
      },
      child: Actions(
        actions: {
          _NextMediaIntent: CallbackAction<_NextMediaIntent>(
            onInvoke: (_) => _navigateToNext(),
          ),
          _PreviousMediaIntent: CallbackAction<_PreviousMediaIntent>(
            onInvoke: (_) => _navigateToPrevious(),
          ),
          _DeleteMediaIntent: CallbackAction<_DeleteMediaIntent>(
            onInvoke: (_) => _deleteCurrent(),
          ),
          _ToggleFavoriteIntent: CallbackAction<_ToggleFavoriteIntent>(
            onInvoke: (_) => _toggleFavorite(),
          ),
          _AddToAlbumIntent: CallbackAction<_AddToAlbumIntent>(
            onInvoke: (_) => _addToAlbum(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
        appBar: AppBar(
          title: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Text(l10n.appTitle);
            },
          ),
          actions: [
            PopupMenuButton<Locale>(
              icon: const Icon(Icons.language),
              tooltip: 'Language / 语言',
              onSelected: (locale) {
                widget.onLocaleChanged?.call(locale);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: Locale('zh'),
                  child: Text('中文'),
                ),
                const PopupMenuItem(
                  value: Locale('en'),
                  child: Text('English'),
                ),
              ],
            ),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return IconButton(
                  icon: const Icon(Icons.folder_open),
                  tooltip: l10n.selectFolderTooltip,
                  onPressed: _selectDirectory,
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _mediaItems.isEmpty
                ? Center(
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_library, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              l10n.pleaseSelectFolder,
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _selectDirectory,
                              icon: const Icon(Icons.folder_open),
                              label: Text(l10n.selectFolder),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                : Row(
                    children: [
                      // 左侧：媒体查看器
                      Expanded(
                        flex: 3,
                        child: Container(
                          color: Colors.black87,
                          child: Stack(
                            children: [
                              Center(
                                child: _currentIndex < _mediaItems.length
                                    ? MediaViewer(item: _mediaItems[_currentIndex])
                                    : const SizedBox(),
                              ),
                              // 导航按钮
                              Positioned(
                                left: 20,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: IconButton(
                                    icon: const Icon(Icons.chevron_left, size: 48),
                                    color: Colors.white70,
                                    onPressed: _currentIndex > 0 ? _navigateToPrevious : null,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 20,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: IconButton(
                                    icon: const Icon(Icons.chevron_right, size: 48),
                                    color: Colors.white70,
                                    onPressed: _currentIndex < _mediaItems.length - 1
                                        ? _navigateToNext
                                        : null,
                                  ),
                                ),
                              ),
                              // 媒体信息
                              if (_currentIndex < _mediaItems.length)
                                Positioned(
                                  top: 20,
                                  left: 20,
                                  right: 20,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _mediaItems[_currentIndex].name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_currentIndex + 1} / ${_mediaItems.length}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // 右侧：操作面板
                      Container(
                        width: 300,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 快捷键提示
                            Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context)!;
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.shortcuts,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ShortcutHint(action: l10n.previousImage, shortcut: '← / A'),
                                        const SizedBox(height: 4),
                                        ShortcutHint(action: l10n.nextImage, shortcut: '→ / D'),
                                        const SizedBox(height: 4),
                                        ShortcutHint(action: l10n.delete, shortcut: 'Delete'),
                                        const SizedBox(height: 4),
                                        ShortcutHint(action: l10n.favorite, shortcut: 'F'),
                                        const SizedBox(height: 4),
                                        ShortcutHint(action: l10n.addToAlbum, shortcut: 'S'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // 操作按钮
                            Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context)!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _navigateToPrevious,
                                      icon: const Icon(Icons.chevron_left),
                                      label: Text(l10n.previousImage),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(16),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: _navigateToNext,
                                      icon: const Icon(Icons.chevron_right),
                                      label: Text(l10n.nextImage),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(16),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _deleteCurrent,
                                      icon: const Icon(Icons.delete),
                                      label: Text(l10n.delete),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(16),
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: _toggleFavorite,
                                      icon: Icon(
                                        _currentIndex < _mediaItems.length &&
                                                _mediaItems[_currentIndex].isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                      ),
                                      label: Text(
                                        _currentIndex < _mediaItems.length &&
                                                _mediaItems[_currentIndex].isFavorite
                                            ? l10n.removeFromFavorites
                                            : l10n.addToFavorites,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(16),
                                        backgroundColor: _currentIndex < _mediaItems.length &&
                                                _mediaItems[_currentIndex].isFavorite
                                            ? Colors.amber
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: _addToAlbum,
                                      icon: const Icon(Icons.album),
                                      label: Text(l10n.addToAlbum),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(16),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const Spacer(),
                            // 当前状态
                            if (_currentIndex < _mediaItems.length)
                              Builder(
                                builder: (context) {
                                  final l10n = AppLocalizations.of(context)!;
                                  return Card(
                                    color: Colors.blue.shade50,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.currentStatus,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (_mediaItems[_currentIndex].isFavorite)
                                            Row(
                                              children: [
                                                const Icon(Icons.favorite, size: 16, color: Colors.amber),
                                                const SizedBox(width: 4),
                                                Text(l10n.favorited),
                                              ],
                                            ),
                                          if (_mediaItems[_currentIndex].albumName != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.album, size: 16, color: Colors.blue),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    '${l10n.album}: ${_mediaItems[_currentIndex].albumName}',
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _AlbumDialog extends StatelessWidget {
  final List<String> albumNames;

  const _AlbumDialog({required this.albumNames});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.selectAlbum),
      content: SizedBox(
        width: 300,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: albumNames.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.createNewAlbum),
                onTap: () => Navigator.pop(context, '_new_'),
              );
            }
            final albumName = albumNames[index - 1];
            return ListTile(
              leading: const Icon(Icons.album),
              title: Text(albumName),
              onTap: () => Navigator.pop(context, albumName),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

