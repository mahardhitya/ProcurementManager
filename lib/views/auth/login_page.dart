import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk session user
import 'package:procurement/core/restapi.dart';
import 'register_page.dart'; // Import halaman register agar bisa navigasi
import 'user_division/dashboard_user.dart'; // Import dashboard user
import '../admin/admin_dashboard.dart'; // Import dashboard admin
import 'widgets/success_dialog.dart'; // Import success dialog

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controller untuk mengambil text input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscure = true; // Untuk fitur Show/Hide Password
  bool _isLoading = false;

  // Fungsi saat tombol Login ditekan
  void _handleLogin() async {
    // Validasi input kosong (US-003)
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email dan Password tidak boleh kosong"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // BYPASS LOGIN UNTUK ADMIN (Hard-coded untuk testing)
      if (_emailController.text == 'admin@admin.com' &&
          _passwordController.text == 'admin') {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Simpan data admin ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', 'admin-001');
          await prefs.setString('user_email', 'admin@admin.com');
          await prefs.setString('user_name', 'Admin');
          await prefs.setString('user_role', 'admin');
          await prefs.setString('division_name', 'MANAGEMENT');

          print('Admin logged in via bypass'); // Debug log

          // Tampilkan success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black.withOpacity(0.5),
            builder: (context) => SuccessDialog(
              title: 'Login Berhasil!',
              message: 'Selamat datang, Admin',
              onComplete: () {
                Navigator.of(context).pop(); // Tutup dialog
                // Admin langsung ke dashboard admin
                Navigator.pushReplacementNamed(context, '/admin/dashboard');
              },
            ),
          );
          return; // Exit function
        }
      }

      // Cari user berdasarkan email dari database
      DataService dataService = DataService();

      print('Attempting login with email: ${_emailController.text}'); // Debug

      // Debug: Coba ambil semua users dulu untuk memastikan koneksi benar
      String allUsersResponse = await dataService.selectAll(
        '690e9167fcee2015d33ec941', // token
        'procumon', // project
        'users', // collection
        '694be4983d9a020fbd727828', // appid
      );
      print('All Users Response: $allUsersResponse'); // Debug

      String response = await dataService.selectWhere(
        '690e9167fcee2015d33ec941', // token
        'procumon', // project
        'users', // collection
        '694be4983d9a020fbd727828', // appid (FIXED: sama dengan registrasi)
        'email', // field
        _emailController.text, // value
      );

      print('Login Response: $response'); // Debug
      print('Response length: ${response.length}'); // Debug

      var jsonResponse = json.decode(response);
      print('Decoded data type: ${jsonResponse.runtimeType}'); // Debug
      print('Decoded data: $jsonResponse'); // Debug

      // Response API format: {"limit":0,"offset":0,"total":1,"data":[...]}
      // Jadi perlu ambil jsonResponse['data'] yang merupakan List users
      List<dynamic> users = [];
      
      if (jsonResponse is Map && jsonResponse['data'] != null) {
        users = jsonResponse['data'] as List<dynamic>;
      } else if (jsonResponse is List) {
        users = jsonResponse;
      }

      print('Users found: ${users.length}'); // Debug

      if (users.isNotEmpty) {
        var user = users[0];
        print('Found user: ${user['email']}, Role: ${user['role']}'); // Debug

        String storedPassword = user['password'] ?? '';
        String userRole = user['role'] ?? 'user';
        String userName = user['name'] ?? 'User';
        String userDivision = user['division_id'] ?? 'IT';

        // Validasi password
        if (storedPassword == _passwordController.text) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            // Simpan data user ke SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', user['id'] ?? user['_id'] ?? '');
            await prefs.setString('user_email', _emailController.text);
            await prefs.setString('user_name', userName);
            await prefs.setString('user_role', userRole);
            await prefs.setString('division_name', userDivision);

            print('User logged in: $userName, Role: $userRole'); // Debug log

            // Tampilkan success dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.black.withOpacity(0.5),
              builder: (context) => SuccessDialog(
                title: 'Login Berhasil!',
                message: 'Selamat datang, $userName',
                onComplete: () {
                  Navigator.of(context).pop(); // Tutup dialog

                  // Routing berdasarkan role (case-insensitive)
                  if (userRole.toLowerCase() == 'admin') {
                    // Admin ke dashboard admin
                    Navigator.pushReplacementNamed(context, '/admin/dashboard');
                  } else {
                    // User biasa ke dashboard user
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardUser(),
                      ),
                    );
                  }
                },
              ),
            );
          }
        } else {
          // Password salah
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Password salah"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Email tidak ditemukan
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Email tidak terdaftar"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error login: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              // --- HEADER ILUSTRASI (Optional) ---
              Center(
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_outlined,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- JUDUL HALAMAN ---
              const Text(
                "Login Account",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Text(
                "Welcome back, please enter your details.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // --- INPUT EMAIL ---
              _buildLabel("Email Address"),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration("Enter your email"),
              ),
              const SizedBox(height: 20),

              // --- INPUT PASSWORD ---
              _buildLabel("Password"),
              TextField(
                controller: _passwordController,
                obscureText: _isObscure,
                decoration: _inputDecoration("Enter your password").copyWith(
                  // Tombol Mata (US-007)
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Lupa Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Fitur reset password (bisa ditambahkan nanti)
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.blue, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // --- TOMBOL LOGIN ---
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
              // --- LINK KE REGISTER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigasi ke Halaman Register
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
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

  // Widget Helper untuk Label
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  // Widget Helper untuk Style Input
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
    );
  }
}
