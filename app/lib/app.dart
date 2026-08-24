import 'package:flutter/material.dart';

import 'features/discovery/device_list_screen.dart';

class LedctlApp extends StatelessWidget {
  const LedctlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ledctl',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const DeviceListScreen(),
    );
  }
}
