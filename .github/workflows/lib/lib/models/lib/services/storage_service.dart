import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _key = 'saved_configs';

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> save(List<String> raws) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, raws);
  }

  static Future<void> add(String raw) async {
    final list = await load();
    if (!list.contains(raw)) {
      list.add(raw);
      await save(list);
    }
  }

  static Future<void> remove(String raw) async {
    final list = await load();
    list.remove(raw);
    await save(list);
  }
}
