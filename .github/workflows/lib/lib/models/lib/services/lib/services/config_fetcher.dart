import 'package:http/http.dart' as http;
import '../models/config_model.dart';

class ConfigFetcher {
  static const List<String> sources = [
    'https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/refs/heads/main/vless_configs.txt',
    'https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/refs/heads/main/vmess_configs.txt',
    'https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/refs/heads/main/ss_configs.txt',
    'https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/Protocols/vless.txt',
    'https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/Protocols/trojan.txt',
    'https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/all_configs.txt',
    'https://raw.githubusercontent.com/mahdibland/V2RayAggregator/master/sub/sub_merge.txt',
  ];

  static Future<List<V2RayConfig>> fetchAll({
    void Function(int done, int total)? onProgress,
  }) async {
    final List<V2RayConfig> result = [];
    final Set<String> seen = {};
    int completed = 0;

    final futures = sources.map((url) async {
      final list = await _fetchOne(url, seen);
      completed++;
      onProgress?.call(completed, sources.length);
      return list;
    });

    final lists = await Future.wait(futures);
    for (final l in lists) {
      result.addAll(l);
    }
    return result;
  }

  static Future<List<V2RayConfig>> _fetchOne(
    String url,
    Set<String> seen,
  ) async {
    final List<V2RayConfig> local = [];
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return local;

      for (final line in res.body.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || seen.contains(trimmed)) continue;
        final cfg = V2RayConfig.fromRaw(trimmed);
        if (cfg != null) {
          seen.add(trimmed);
          local.add(cfg);
        }
      }
    } catch (_) {}
    return local;
  }
}
