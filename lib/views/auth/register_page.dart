import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:procurement/core/restapi.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controller untuk mengambil text dari inputan
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // Daftar divisi yang tersedia
  final List<String> _divisions = [
    'IT',
    'Marketing',
    'Operations',
  ];
  String? _selectedDivision;

  // Fungsi saat tombol Sign Up ditekan
  void _handleRegister() async {
    // Validasi input kosong
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedDivision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua kolom harus diisi!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // PANGGIL API YANG BENARAN
    DataService dataService = DataService();

    // Perhatikan urutan parameternya harus sama dengan di restapi.dart
    // (appid, name, email, password, role, division_id, ...)
    String response = await dataService.insertUsers(
      '694be4983d9a020fbd727828', // App ID dari config.dart
      _nameController.text,
      _emailController.text,
      _passwordController.text,
      'user', // Role default (ganti dari 'divisi')
      _selectedDivision!, // Gunakan divisi yang dipilih
      '', // Add the 7th argument - check insertUsers method signature for what this should be
    );

    var data = jsonDecode(response);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Cek apakah response mengandung error
      if (response.contains('error')) {
        // Ada error dari server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal Register: $response"),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Validasi Hasil: Jika data bukan list kosong, berarti sukses
        try {
          if (data is List && data.isNotEmpty) {
            // SUKSES BENARAN
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Registrasi Berhasil! Data Tersimpan."),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context); // Balik ke Login
          } else {
            // GAGAL - data kosong
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Gagal Register: Data tidak tersimpan"),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error parsing response: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context), // Tombol back manual
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Text(
                "Sign up to get started!",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 30),

              // --- FORM INPUT ---
              _buildTextField("Full Name", "Enter your name", _nameController),
              const SizedBox(height: 20),
              _buildTextField("Email Address", "Enter email", _emailController),
              const SizedBox(height: 20),

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

              const SizedBox(height: 20),
              _buildTextField(
                "Password",
                "Create password",
                _passwordController,
                isPassword: true,
              ),

              const SizedBox(height: 40),

              // --- TOMBOL SIGN UP ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Sign Up",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 20),
              // Link balik ke Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.pop(context), // Balik ke Login
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget kecil biar kodingan rapi (Input Field Modern)
  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none, // Border hilang biar modern
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
          ),
        ),
      ],
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
