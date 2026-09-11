import 'dart:async';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import '../models/config_model.dart';

class VpnService {
  VpnService._();
  static final VpnService instance = VpnService._();

  late V2ray _v2ray;
  bool _initialized = false;

  final _statusCtrl = StreamController<V2RayStatus>.broadcast();
  Stream<V2RayStatus> get statusStream => _statusCtrl.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _v2ray = V2ray(
      onStatusChanged: (status) => _statusCtrl.add(status),
    );
    await _v2ray.initialize(
      notificationIconResourceType: "mipmap",
      notificationIconResourceName: "ic_launcher",
    );
    _initialized = true;
  }

  Future<bool> connect(V2RayConfig cfg) async {
    if (!_initialized) await initialize();
    V2RayURL parser = V2ray.parseFromURL(cfg.raw);
    final granted = await _v2ray.requestPermission();
    if (!granted) return false;

    await _v2ray.startV2Ray(
      remark: cfg.name,
      config: parser.getFullConfiguration(),
      blockedApps: null,
      bypassSubnets: null,
      proxyOnly: false,
    );
    return true;
  }

  Future<void> disconnect() async {
    await _v2ray.stopV2Ray();
  }

  Future<int> getServerDelay(String raw) async {
    V2RayURL parser = V2ray.parseFromURL(raw);
    return await _v2ray.getServerDelay(
      config: parser.getFullConfiguration(),
    );
  }

  Future<bool> isRunning() async => await _v2ray.isRunning();
}
