import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';

// Import halaman
import 'views/auth/login_page.dart';
import 'views/auth/register_page.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/admin/monthly_detail_page.dart';
import 'views/user/user_dashboard.dart';
import 'views/user/add_request_screen.dart';
import 'views/user/profile_screen.dart';
import 'models/monthly_budgets_model.dart';

void main() {
  runApp(
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
      title: 'Procurement Monitoring',
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

      initialRoute: '/login', 
      
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/admin/dashboard': (context) => const AdminDashboard(),
        '/user/dashboard': (context) => const UserDashboard(),
        '/profile': (context) => const ProfileScreen(),
        '/admin/month-detail': (context) {
          final budget = ModalRoute.of(context)?.settings.arguments as MonthlyBudgetsModel?;
          return MonthlyDetailPage(budget: budget ?? MonthlyBudgetsModel(id: '', fiscal_year_id: '', month_name: '', month_index: '', total_revenue: '', total_expense: '', is_surplus: ''));
        },
        '/monthly-detail': (context) {
          final budget = ModalRoute.of(context)?.settings.arguments as MonthlyBudgetsModel?;
          return MonthlyDetailPage(budget: budget ?? MonthlyBudgetsModel(id: '', fiscal_year_id: '', month_name: '', month_index: '', total_revenue: '', total_expense: '', is_surplus: ''));
        },
        '/add-request': (context) {
          // TODO: Get from session
          return const AddRequestScreen(
            monthlyBudgetId: '',
            userId: '',
            divisionName: '',
          );
        },
      },
    );
  }
}