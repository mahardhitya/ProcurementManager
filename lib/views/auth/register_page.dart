import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:procurement/core/config.dart';
import 'package:procurement/core/restapi.dart';
import 'package:procurement/models/divisions_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _passwordConfirm = TextEditingController();

  String _selectedRole = 'user';
  String _selectedDivision = '';
  List<DivisionsModel> _divisions = [];
  bool _loading = false;
  bool _showPassword = false;
  bool _showPasswordConfirm = false;

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  Future<void> _loadDivisions() async {
    setState(() => _loading = true);
    try {
      final svc = DataService();
      final resp = await svc.getAll('divisions', AppConfig.appid);
      debugPrint('DEBUG: API Response = $resp');
      final data = json.decode(resp);

      if (data is List && data.isNotEmpty) {
        if (mounted) {
          setState(() {
            _divisions = data.map((d) => DivisionsModel.fromJson(d)).toList();
            if (_divisions.isNotEmpty) {
              _selectedDivision = _divisions[0].id;
            }
            _loading = false;
          });
        }
      } else {
        // Fallback: Hardcode data divisi jika API kosong/error
        debugPrint('DEBUG: API response kosong atau bukan List, gunakan hardcode');
        if (mounted) {
          setState(() {
            _divisions = [
              DivisionsModel(
                id: '69612cb2045a4b3d08977282',
                name: 'MARKETING-DEPT',
                code: 'MK1',
              ),
              DivisionsModel(
                id: '69612cb2045a4b3d08977283',
                name: 'IT-DEPT',
                code: 'IT1',
              ),
            ];
            if (_divisions.isNotEmpty) {
              _selectedDivision = _divisions[0].id;
            }
            _loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('DEBUG: Exception saat load divisions: $e');
      if (mounted) {
        // Fallback jika ada exception
        setState(() {
          _divisions = [
            DivisionsModel(
              id: '69612cb2045a4b3d08977282',
              name: 'MARKETING-DEPT',
              code: 'MK1',
            ),
            DivisionsModel(
              id: '69612cb2045a4b3d08977283',
              name: 'IT-DEPT',
              code: 'IT1',
            ),
          ];
          if (_divisions.isNotEmpty) {
            _selectedDivision = _divisions[0].id;
          }
          _loading = false;
        });
      }
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _register() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text.trim();
    final passwordConfirm = _passwordConfirm.text.trim();

    // Validasi
    if (name.isEmpty) {
      _showToast('Nama tidak boleh kosong');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showToast('Email tidak valid');
      return;
    }
    if (password.isEmpty || password.length < 6) {
      _showToast('Password minimal 6 karakter');
      return;
    }
    if (password != passwordConfirm) {
      _showToast('Konfirmasi password tidak sesuai');
      return;
    }
    if (_selectedDivision.isEmpty) {
      _showToast('Pilih divisi terlebih dahulu');
      return;
    }

    setState(() => _loading = true);

    try {
      // Cek email sudah ada atau belum
      final svc = DataService();
      final checkResp = await svc.selectWhere('users', AppConfig.appid, 'email', email);
      final checkData = json.decode(checkResp);

      if (checkData is List && checkData.isNotEmpty) {
        _showToast('Email sudah terdaftar');
        setState(() => _loading = false);
        return;
      }

      // Ambil division name
      final divisionName = _divisions.firstWhere((d) => d.id == _selectedDivision).name;

      // Insert user
      final body = {
        'name': name,
        'email': email,
        'password': password,
        'role': _selectedRole,
        'division_id': _selectedDivision,
        'division_name': divisionName,
      };

      final resp = await svc.insertData('users', AppConfig.appid, body);
      debugPrint('DEBUG REGISTER: API Response = $resp');
      final insertData = json.decode(resp);
      debugPrint('DEBUG REGISTER: Parsed Data = $insertData');

      if (insertData is Map && insertData.containsKey('id')) {
        _showSuccessToast('Pendaftaran berhasil! Silakan login');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        debugPrint('DEBUG REGISTER: Insert gagal - bukan Map atau tidak punya ID');
        _showToast('Pendaftaran gagal, coba lagi');
      }
    } catch (e) {
      _showToast('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, size: 24),
              ),
              const SizedBox(height: 20),

              // Header
              const Text(
                'Daftar Account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const Text(
                'Buat akun baru Anda',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 30),

              // Nama
              const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  hintText: 'Masukkan nama lengkap',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Masukkan email',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _password,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  hintText: 'Minimal 6 karakter',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Konfirmasi Password
              const Text('Konfirmasi Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordConfirm,
                obscureText: !_showPasswordConfirm,
                decoration: InputDecoration(
                  hintText: 'Ulangi password',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPasswordConfirm ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _showPasswordConfirm = !_showPasswordConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Role
              const Text('Role', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ]
                    .map((e) => e)
                    .toList(),
                onChanged: (val) => setState(() => _selectedRole = val ?? 'user'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Divisi
              const Text('Divisi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              _loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(),
                    )
                  : _divisions.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'Tidak ada data divisi tersedia',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          value: _selectedDivision.isEmpty ? null : _selectedDivision,
                          items: _divisions
                              .map((d) => DropdownMenuItem(
                                    value: d.id,
                                    child: Text(d.name),
                                  ))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedDivision = val ?? ''),
                          decoration: InputDecoration(
                            hintText: 'Pilih divisi',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue, width: 2),
                            ),
                          ),
                        ),
              const SizedBox(height: 24),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Daftar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah punya akun? ', style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    child: const Text('Login', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }
}
