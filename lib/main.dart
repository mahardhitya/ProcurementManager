import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'views/auth/splash_screen.dart';
import 'views/auth/login_page.dart';
import 'views/auth/register_page.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/admin/input_revenue_page.dart';
import 'views/admin/admin_setup_page.dart';

void main() {
  runApp(DevicePreview(enabled: true, builder: (context) => const MyApp()));
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

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),

      home: const SplashScreen(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/admin/dashboard': (context) => const AdminDashboard(),
        '/admin/input-revenue': (context) => const InputRevenuePage(),
        '/admin/setup': (context) => const AdminSetupPage(),
      },
    );
  }
}
