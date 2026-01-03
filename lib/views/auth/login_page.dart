import 'package:flutter/material.dart';
import 'register_page.dart'; // Import halaman register agar bisa navigasi
import 'user_division/dashboard_user.dart'; // Import dashboard
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

  // Daftar divisi yang tersedia
  final List<String> _divisions = ['IT', 'Marketing', 'Operations'];
  String? _selectedDivision;

  // Fungsi saat tombol Login ditekan
  void _handleLogin() async {
    // Validasi input kosong (US-003)
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedDivision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email, Password, dan Divisi tidak boleh kosong"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulasi request ke API (Nanti diganti dengan logic RestAPI)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Tampilkan success dialog yang menarik
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (context) => SuccessDialog(
          title: 'Login Berhasil!',
          message: 'Selamat datang di ProcuMon',
          onComplete: () {
            Navigator.of(context).pop(); // Tutup dialog
            // Navigasi ke Dashboard dengan pushReplacement
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DashboardUser(userDivision: _selectedDivision!),
              ),
            );
          },
        ),
      );
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

              // --- DROPDOWN DIVISI ---
              _buildLabel("Division"),
              DropdownButtonFormField<String>(
                value: _selectedDivision,
                decoration: _inputDecoration("Select your division"),
                items: _divisions.map((division) {
                  return DropdownMenuItem(
                    value: division,
                    child: Text(division),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDivision = value;
                  });
                },
              ),

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
