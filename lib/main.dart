import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart'; // Import plugin ini
import 'views/auth/splash_screen.dart'; // Import splash screen

void main() {
  runApp(
    // Bungkus MyApp dengan DevicePreview
    DevicePreview(enabled: true, builder: (context) => const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProcuMon',
      debugShowCheckedModeBanner: false,

      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      // ---------------------------------------
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),

      home: const SplashScreen(), // Mulai dengan splash screen
    );
  }
}
