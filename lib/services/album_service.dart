import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AlbumService {
  static const String _albumsKey = 'albums';

  static Future<Map<String, List<String>>> getAlbums() async {
    final prefs = await SharedPreferences.getInstance();
    final albumsJson = prefs.getString(_albumsKey);
    if (albumsJson == null) {
      return {};
    }
    final Map<String, dynamic> decoded = jsonDecode(albumsJson);
    return decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
  }

  static Future<List<String>> getAlbumNames() async {
    final albums = await getAlbums();
    return albums.keys.toList()..sort();
  }

  static Future<void> addToAlbum(String albumName, String filePath) async {
    final albums = await getAlbums();
    if (!albums.containsKey(albumName)) {
      albums[albumName] = [];
    }
    if (!albums[albumName]!.contains(filePath)) {
      albums[albumName]!.add(filePath);
    }
    await _saveAlbums(albums);
  }

  static Future<void> removeFromAlbum(String albumName, String filePath) async {
    final albums = await getAlbums();
    if (albums.containsKey(albumName)) {
      albums[albumName]!.remove(filePath);
      if (albums[albumName]!.isEmpty) {
        albums.remove(albumName);
      }
      await _saveAlbums(albums);
    }
  }

  static Future<void> createAlbum(String albumName) async {
    final albums = await getAlbums();
    if (!albums.containsKey(albumName)) {
      albums[albumName] = [];
      await _saveAlbums(albums);
    }
  }

  static Future<void> deleteAlbum(String albumName) async {
    final albums = await getAlbums();
    albums.remove(albumName);
    await _saveAlbums(albums);
  }

  static Future<void> _saveAlbums(Map<String, List<String>> albums) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_albumsKey, jsonEncode(albums));
  }

  static Future<String?> getAlbumForMedia(String filePath) async {
    final albums = await getAlbums();
    for (var entry in albums.entries) {
      if (entry.value.contains(filePath)) {
        return entry.key;
      }
    }
    return null;
  }
}

