import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';

// --- IMPORT HALAMAN ---
import 'views/auth/login_page.dart';
import 'views/auth/user_division/dashboard_user.dart';
import 'views/admin/dashboard_admin_page.dart';
// Pastikan Anda mengimport halaman Detail Bulan & Profile yang sudah dibuat sebelumnya
import 'views/admin/admin_month_detail_page.dart'; // Sesuaikan path ini dengan file Anda
 // Sesuaikan path ini (jika ada fitur profile)

void main() {
  runApp(
    DevicePreview(
      enabled: true, // Ubah ke false jika ingin build rilis (APK)
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance App',
      debugShowCheckedModeBanner: false,
      
      // Konfigurasi Device Preview
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

      // --- PENGATURAN ROUTE (PENTING) ---
      // Tentukan halaman awal aplikasi
      initialRoute: '/admin/dashboard', 
      
      // Daftarkan semua nama route di sini agar pushNamed berfungsi
      routes: {
        // Route Login
        '/login': (context) => const LoginPage(),
        
        // Route Admin
        '/admin/dashboard': (context) => const AdminDashboardPage(),
        '/admin/month-detail': (context) => const AdminMonthDetailPage(), 
        // Route User Divisi
        '/user/dashboard': (context) => const DashboardUser(),
        

      },
    );
  }
}