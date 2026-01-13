import 'package:flutter/material.dart';
import 'package:procurement/utils/admin_seeder.dart';

/// Halaman untuk setup admin account (hanya dijalankan sekali)
class AdminSetupPage extends StatefulWidget {
  const AdminSetupPage({super.key});

  @override
  State<AdminSetupPage> createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  final AdminSeeder _seeder = AdminSeeder();
  bool _loading = false;
  String _message = '';
  bool _success = false;

  Future<void> _setupAdmin() async {
    setState(() {
      _loading = true;
      _message = 'Memeriksa dan membuat akun admin...';
    });

    try {
      final success = await _seeder.createAdminAccount();
      
      setState(() {
        _success = success;
        if (success) {
          _message = 'Akun admin berhasil dibuat!\n\n'
              '📧 Email: admin@procumon.com\n'
              '🔐 Password: admin123\n\n'
              'Silakan login dengan kredensial di atas.';
        } else {
          _message = 'Gagal membuat akun admin. Coba lagi.';
        }
      });

      // Auto navigate ke login setelah 3 detik jika berhasil
      if (success) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      setState(() {
        _success = false;
        _message = 'Error: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Setup Admin Account'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _success ? Icons.check_circle : Icons.admin_panel_settings,
                size: 80,
                color: _success ? Colors.green : Colors.blue,
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Setup Akun Administrator',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Text(
                _message.isEmpty
                    ? 'Klik tombol di bawah untuk membuat akun admin default'
                    : _message,
                style: TextStyle(
                  fontSize: 16,
                  color: _success ? Colors.green[700] : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              if (!_success && !_loading)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _setupAdmin,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Buat Akun Admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              
              if (_loading)
                const CircularProgressIndicator(),
              
              if (_success)
                Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Mengarahkan ke halaman login...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              
              const SizedBox(height: 32),
              
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Lewati (Sudah Punya Akun)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
