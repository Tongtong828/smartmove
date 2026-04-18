import 'package:amap_flutter/amap_flutter.dart';
import 'package:flutter/material.dart';

import 'page/nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AMapFlutter.init(
    apiKey: ApiKey(
      androidKey: '21c52760a4cb63f4b3682cf50e74e41d',
      iosKey: '',
      webKey: '',
    ),
    agreePrivacy: true,
  );

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