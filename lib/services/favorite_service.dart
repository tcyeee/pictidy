import 'package:shared_preferences/shared_preferences.dart';
import 'package:pictidy/models/media_item.dart';

class FavoriteService {
  static const String _favoritesKey = 'favorites';

  static Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    return favorites.toSet();
  }

  static Future<void> addFavorite(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.add(filePath);
    await prefs.setStringList(_favoritesKey, favorites.toList());
  }

  static Future<void> removeFavorite(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.remove(filePath);
    await prefs.setStringList(_favoritesKey, favorites.toList());
  }

  static Future<bool> isFavorite(String filePath) async {
    final favorites = await getFavorites();
    return favorites.contains(filePath);
  }

  static Future<void> toggleFavorite(MediaItem item) async {
    final isFav = await isFavorite(item.path);
    if (isFav) {
      await removeFavorite(item.path);
    } else {
      await addFavorite(item.path);
    }
  }
}

