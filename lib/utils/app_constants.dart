import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Budget Management';
  static const String appVersion = '1.0.0';
  static const String appId = 'budget_app'; 
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleDivisi = 'divisi';
  
  // Status Request
  static const String statusPending = 'Pending';
  static const String statusApproved = 'Approved';
  static const String statusRejected = 'Rejected';
  
  // Fiscal Year Status
  static const String fiscalActive = 'Active';
  static const String fiscalClosed = 'Closed';
  
  // Months
  static const List<String> monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  
  // Base Colors
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF42A5F5);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color warningColor = Color(0xFFFB8C00);
  
  // Logic Warna Status Request (US-022)
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return warningColor; // Kuning/Oranye
      case 'approved':
        return successColor; // Hijau
      case 'rejected':
        return errorColor;   // Merah
      default:
        return Colors.grey;
    }
  }
  
  // Logic Warna Budget Dashboard (US-011)
  static Color getBudgetStatusColor(double revenue, double expense) {
    if (revenue == 0 && expense == 0) return Colors.grey.shade300;
    if (revenue > expense) return Colors.green.shade100; // Surplus
    return Colors.red.shade100; // Defisit
  }
}

class AppHelpers {
  // Format Currency (Rp 100.000)
  static String formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
  
  // Parse Currency (Menghapus titik agar bisa jadi double)
  static double parseCurrency(String text) {
    // Hapus 'Rp ' dan titik, lalu parse
    String cleanText = text.replaceAll('Rp ', '').replaceAll('.', '').trim();
    return double.tryParse(cleanText) ?? 0;
  }
  
  // Validate Email Regex
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
  
  // Hitung Persentase
  static double calculatePercentage(double value, double total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }
  
  // Warna Progress Bar (Hijau -> Kuning -> Merah)
  static Color getProgressColor(double percentage) {
    if (percentage > 100) return AppConstants.errorColor; // Over budget
    if (percentage > 80) return AppConstants.warningColor; // Warning limit
    return AppConstants.successColor; // Safe
  }
  
  // --- SNACKBAR & DIALOGS ---

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hapus snackbar lama jika ada
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }
  
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  static Future<bool> showConfirmDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Ya',
    String cancelText = 'Tidak',
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: isDanger ? ElevatedButton.styleFrom(backgroundColor: Colors.red) : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  // Dialog Loading (Blocking)
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa tap luar untuk tutup
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
  
  // Tutup Dialog Loading
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class AppValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!AppHelpers.isValidEmail(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }
  
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }
  
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName harus berupa angka';
    }
    if (double.parse(value) <= 0) {
      return '$fieldName harus lebih dari 0';
    }
    return null;
  }
}