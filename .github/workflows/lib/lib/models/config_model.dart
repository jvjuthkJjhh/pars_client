import 'dart:convert';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';

class V2RayConfig {
  final String raw;
  final String protocol;
  final String name;
  final String host;
  final int port;
  int? tcpPing;
  int? realPing;

  V2RayConfig({
    required this.raw,
    required this.protocol,
    required this.name,
    required this.host,
    required this.port,
  });

  static V2RayConfig? fromRaw(String raw) {
    raw = raw.trim();
    if (raw.isEmpty) return null;

    try {
      V2RayURL parser = V2ray.parseFromURL(raw);

      String protocol = 'Unknown';
      if (raw.startsWith('vmess://')) {
        protocol = 'VMess';
      } else if (raw.startsWith('vless://')) {
        protocol = 'VLESS';
      } else if (raw.startsWith('trojan://')) {
        protocol = 'Trojan';
      } else if (raw.startsWith('ss://')) {
        protocol = 'Shadowsocks';
      } else {
        return null;
      }

      String host = '';
      int port = 0;

      try {
        final fullConfig = jsonDecode(parser.getFullConfiguration());
        final outbounds = fullConfig['outbounds'] as List?;
        if (outbounds != null) {
          for (final ob in outbounds) {
            final settings = ob['settings'];
            if (settings == null) continue;
            if (settings['vnext'] != null &&
                (settings['vnext'] as List).isNotEmpty) {
              host = settings['vnext'][0]['address'] ?? '';
              port = settings['vnext'][0]['port'] ?? 0;
              break;
            }
            if (settings['servers'] != null &&
                (settings['servers'] as List).isNotEmpty) {
              host = settings['servers'][0]['address'] ?? '';
              port = settings['servers'][0]['port'] ?? 0;
              break;
            }
          }
        }
      } catch (_) {}

      return V2RayConfig(
        raw: raw,
        protocol: protocol,
        name: parser.remark.isNotEmpty ? parser.remark : 'Server',
        host: host,
        port: port,
      );
    } catch (_) {
      return null;
    }
  }

  int? get bestPing => realPing ?? tcpPing;
}
