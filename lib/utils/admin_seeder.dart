import 'dart:convert';
import 'package:procurement/core/config.dart';
import 'package:procurement/core/restapi.dart';

/// Utility untuk membuat akun admin default
/// Jalankan sekali untuk inisialisasi data admin
class AdminSeeder {
  final DataService _svc = DataService();

  /// Cek apakah admin sudah ada
  Future<bool> adminExists() async {
    try {
      final resp = await _svc.selectWhere(
        AppConfig.token,
        AppConfig.project,
        'users',
        AppConfig.appid,
        'email',
        'admin@procumon.com',
      );
      
      final data = json.decode(resp);
      return data is List && data.isNotEmpty;
    } catch (e) {
      print('Error checking admin: $e');
      return false;
    }
  }

  /// Buat akun admin default
  Future<bool> createAdminAccount() async {
    try {
      // Cek apakah admin sudah ada
      if (await adminExists()) {
        print('Admin account already exists');
        return true;
      }

      // Get first division (atau buat division khusus admin)
      final divResp = await _svc.selectAll(
        AppConfig.token,
        AppConfig.project,
        'divisions',
        AppConfig.appid,
      );
      
      final divData = json.decode(divResp);
      String divisionId = '';
      String divisionName = 'MANAGEMENT';
      
      if (divData is List && divData.isNotEmpty) {
        divisionId = divData[0]['id'];
        divisionName = divData[0]['name'];
      }

      // Insert admin user
      final result = await _svc.insertUsers(
        AppConfig.token,
        AppConfig.appid,
        'Administrator',
        'admin@procumon.com',
        'admin123',
        'admin',
        divisionId,
      );

      print('Admin creation result: $result');
      
      // Verifikasi
      final exists = await adminExists();
      if (exists) {
        print('✅ Admin account created successfully!');
        print('Email: admin@procumon.com');
        print('Password: admin123');
        print('Division: $divisionName');
      }
      
      return exists;
    } catch (e) {
      print('Error creating admin: $e');
      return false;
    }
  }
}
