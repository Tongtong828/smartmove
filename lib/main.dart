import 'package:flutter/material.dart';

import 'page/nav.dart';
import 'store/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CheckInStore.instance.init();

  runApp(const SmartMoveApp());
}

class SmartMoveApp extends StatelessWidget {
  const SmartMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'City Check-in',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const NavPage(),
    );
  }
}