import 'package:flutter/material.dart';
import 'page/nav.dart';

void main() {
  runApp(const SmartMoveApp());
}

class SmartMoveApp extends StatelessWidget {
  const SmartMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartMove',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const NavPage(),
    );
  }
}