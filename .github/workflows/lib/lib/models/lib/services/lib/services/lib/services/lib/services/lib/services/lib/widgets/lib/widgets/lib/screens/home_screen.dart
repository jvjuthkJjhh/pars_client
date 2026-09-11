import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/config_model.dart';
import '../services/config_fetcher.dart';
import '../services/ping_service.dart';
import '../services/vpn_service.dart';
import '../services/storage_service.dart';
import '../widgets/connect_button.dart';
import '../widgets/config_tile.dart';
import '../widgets/stats_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _vpn = VpnService.instance;

  List<V2RayConfig> configs = [];
  V2RayConfig? selected;

  bool loading = false;
  bool connecting = false;
  bool connected = false;
  String statusText = 'قطع';
  String progressText = '';

  int? _downSpeed;
  int? _upSpeed;
  DateTime? _connectTime;
  Timer? _durationTimer;

  late AnimationController _pulse;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.92,
      upperBound: 1.08,
    )..repeat(reverse: true);

    _vpn.initialize();
    _listenStatus();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final raws = await StorageService.load();
    final list = raws
        .map((r) => V2RayConfig.fromRaw(r))
        .whereType<V2RayConfig>()
        .toList();
    if (list.isNotEmpty && mounted) {
      setState(() {
        configs = list;
        selected = list.first;
      });
    }
  }

  void _listenStatus() {
    _statusSub = _vpn.statusStream.listen((status) {
      if (!mounted) return;
      setState(() {
        if (status.state == V2RayStatus.connected) {
          connected = true;
          connecting = false;
          statusText = 'متصل';
          _connectTime = DateTime.now();
          _startDurationTimer();
        } else if (status.state == V2RayStatus.disconnected) {
          connected = false;
          connecting = false;
          statusText = 'قطع';
          _downSpeed = null;
          _upSpeed = null;
          _stopDurationTimer();
        } else if (status.state == V2RayStatus.connecting) {
          connecting = true;
          statusText = 'در حال اتصال...';
        }
        _downSpeed = status.downloadSpeed;
        _upSpeed = status.uploadSpeed;
      });
    });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _connectTime = null;
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _pulse.dispose();
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleConnection() async {
    if (connecting) return;

    if (connected) {
      setState(() {
        connecting = true;
        statusText = 'در حال قطع...';
      });
      await _vpn.disconnect();
      return;
    }

    if (selected == null) {
      _snack('اول یک کانفیگ انتخاب کن');
      return;
    }

    setState(() {
      connecting = true;
      statusText = 'در حال اتصال...';
    });
    final ok = await _vpn.connect(selected!);
    if (!ok) {
      setState(() {
        connecting = false;
        statusText = 'خطا در اتصال';
      });
    }
  }

  Future<void> _searchConfigs() async {
    setState(() {
      loading = true;
      configs.clear();
      selected = null;
      progressText = 'در حال دریافت کانفیگ‌ها...';
    });

    final fetched = await ConfigFetcher.fetchAll(
      onProgress: (done, total) {
        if (mounted) {
          setState(() => progressText = 'دریافت $done/$total منبع...');
        }
      },
    );

    if (fetched.isEmpty) {
      setState(() {
        loading = false;
        progressText = '';
      });
      _snack('هیچ کانفیگی دریافت نشد');
      return;
    }

    if (mounted) {
      setState(() => progressText = '${fetched.length} کانفیگ — پینگ‌گیری...');
    }

    final pinged = await PingService.pingAll(
      fetched,
      onProgress: (done, total) {
        if (mounted) {
          setState(() => progressText = 'پینگ $done/$total');
        }
      },
    );

    setState(() {
      configs = pinged;
      loading = false;
      progressText = '';
      if (pinged.isNotEmpty) selected = pinged.first;
    });

    _snack('${pinged.length} کانفیگ سالم پیدا شد');
  }

  Future<void> _addManual() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141820),
        title: Text('افزودن کانفیگ',
            style: GoogleFonts.vazirmatn(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'vmess:// یا vless:// ...',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF0A0E14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('افزودن'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;
    final cfg = V2RayConfig.fromRaw(result);
    if (cfg == null) {
      _snack('کانفیگ معتبر نیست');
      return;
    }

    setState(() {
      configs.insert(0, cfg);
      selected = cfg;
    });
    await StorageService.add(cfg.raw);
    _snack('کانفیگ اضافه شد');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.vazirmatn()),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1F6FEB),
      ),
    );
  }

  Duration? get _duration {
    if (_connectTime == null) return null;
    return DateTime.now().difference(_connectTime!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1F6FEB), Color(0xFF00E676)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'پارس کلاینت',
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _addManual,
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.white70),
                    tooltip: 'افزودن کانفیگ',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            ConnectButton(
              connected: connected,
              connecting: connecting,
              onTap: _toggleConnection,
              pulse: _pulse,
            ),

            const SizedBox(height: 8),
            Text(
              statusText,
              style: GoogleFonts.vazirmatn(
                color: connected ? const Color(0xFF00E676) : Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (selected != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${selected!.protocol} • ${selected!.name}',
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 6),

            if (connected)
              StatsCard(
                downSpeed: _downSpeed,
                upSpeed: _upSpeed,
                duration: _duration,
              ),

            if (loading && progressText.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Column(
                  children: [
                    const LinearProgressIndicator(
                      backgroundColor: Color(0xFF141820),
                      color: Color(0xFF1F6FEB),
                      minHeight: 3,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      progressText,
                      style: GoogleFonts.vazirmatn(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: loading ? null : _searchConfigs,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search, size: 20),
                label: Text(
                  loading ? 'در حال جستجو...' : 'جستجوی کانفیگ',
                  style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F6FEB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: configs.isEmpty && !loading
                  ? _emptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: configs.length,
                      itemBuilder: (_, i) {
                        final c = configs[i];
                        return ConfigTile(
                          config: c,
                          isSelected: selected?.raw == c.raw,
                          onTap: () => setState(() => selected = c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dns_outlined, color: Colors.white12, size: 56),
          const SizedBox(height: 10),
          Text(
            'هنوز کانفیگی اضافه نشده',
            style: GoogleFonts.vazirmatn(color: Colors.white24),
          ),
          const SizedBox(height: 6),
          Text(
            'روی «جستجوی کانفیگ» بزن یا + بزن',
            style: GoogleFonts.vazirmatn(color: Colors.white12, fontSize: 11),
          ),
        ],
      ),
    );
  }
