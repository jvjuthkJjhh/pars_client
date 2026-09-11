import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class ConnectButton extends StatelessWidget {
  final bool connected;
  final bool connecting;
  final VoidCallback onTap;
  final Animation<double> pulse;

  const ConnectButton({
    super.key,
    required this.connected,
    required this.connecting,
    required this.onTap,
    required this.pulse,
  });

  Color get _color {
    if (connected) return const Color(0xFF00E676);
    if (connecting) return const Color(0xFFFFB300);
    return const Color(0xFF546E7A);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: connecting ? null : onTap,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, __) => Transform.scale(
          scale: connected ? pulse.value : 1.0,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _color.withOpacity(0.25),
                  _color.withOpacity(0.05),
                ],
              ),
              border: Border.all(color: _color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _color.withOpacity(0.45),
                  blurRadius: 50,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: connecting
                  ? const SpinKitRing(
                      color: Colors.white,
                      size: 60,
                      lineWidth: 3,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          connected ? Icons.shield : Icons.shield_outlined,
                          color: _color,
                          size: 58,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'VPN',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                        if (connected)
                          Text(
                            'فعال',
                            style: GoogleFonts.vazirmatn(
                              color: _color,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
