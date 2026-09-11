import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ParsClientApp());
}

class ParsClientApp extends StatelessWidget {
  const ParsClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'پارس کلاینت',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1F6FEB),
          secondary: Color(0xFF00E676),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
