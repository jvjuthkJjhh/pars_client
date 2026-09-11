import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/config_model.dart';

class ConfigTile extends StatelessWidget {
  final V2RayConfig config;
  final bool isSelected;
  final VoidCallback onTap;

  const ConfigTile({
    super.key,
    required this.config,
    required this.isSelected,
    required this.onTap,
  });

  Color _protocolColor(String p) {
    switch (p) {
      case 'VLESS':
        return const Color(0xFF42A5F5);
      case 'VMess':
        return const Color(0xFFAB47BC);
      case 'Trojan':
        return const Color(0xFFFF7043);
      case 'Shadowsocks':
        return const Color(0xFF26A69A);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ping = config.bestPing;
    final pingColor = ping == null
        ? Colors.redAccent
        : (ping < 200
            ? const Color(0xFF00E676)
            : (ping < 500 ? Colors.orangeAccent : Colors.redAccent));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF1F6FEB).withOpacity(0.18)
            : const Color(0xFF141820),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF1F6FEB) : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _protocolColor(config.protocol).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              config.protocol.substring(0, 2).toUpperCase(),
              style: GoogleFonts.poppins(
                color: _protocolColor(config.protocol),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
        title: Text(
          config.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.vazirmatn(color: Colors.white, fontSize: 13),
        ),
        subtitle: Text(
          config.protocol,
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              ping == null ? '✕' : '$ping',
              style: GoogleFonts.poppins(
                color: pingColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(
              'ms',
              style: GoogleFonts.poppins(color: Colors.white24, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
