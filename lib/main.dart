import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart'; // Import plugin ini
import 'views/auth/login_page.dart'; // Pastikan import ini sesuai dengan folder kamu

void main() {
  runApp(
    // Bungkus MyApp dengan DevicePreview
    DevicePreview(
      enabled: true, 
      builder: (context) => const MyApp(),
    ),
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
      
      home: const LoginPage(), // Ganti dengan halaman awal yang diinginkan
    );
  }
}