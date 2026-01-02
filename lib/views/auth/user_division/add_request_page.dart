import 'package:flutter/material.dart';
import '../../../core/restapi.dart'; // Pastikan path import ini benar
import 'dart:convert';

class AddRequestPage extends StatefulWidget {
  final String monthName; // Kita butuh ini untuk menandai data masuk bulan apa
  const AddRequestPage({super.key, required this.monthName});

  @override
  State<AddRequestPage> createState() => _AddRequestPageState();
}

class _AddRequestPageState extends State<AddRequestPage> {
  // Global Key untuk Validasi Form
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  int _totalPrice = 0;
  bool _isLoading = false;

  // Real-time calculation
  void _calculateTotal() {
    int qty = int.tryParse(_qtyController.text) ?? 0;
    int price = int.tryParse(_priceController.text) ?? 0;
    setState(() {
      _totalPrice = qty * price;
    });
  }

  // CORE LOGIC: Save to GoCloud
  Future<void> _submitToCloud() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dataService = DataService();
      
      // Kita gunakan 'monthName' sebagai 'monthly_budget_id' agar mudah difilter nanti
      // Sesuaikan ID App & Project dengan milikmu
      String response = await dataService.insertProcurementRequests(
        '693cbdff23173f13b93c2291',    // App ID
        widget.monthName,              // Simpan nama bulan di kolom monthly_budget_id
        'USER-123',                    // User ID (Dummy dulu/ambil dari session)
        _itemController.text,
        _qtyController.text,
        _priceController.text,
        _totalPrice.toString(),
        'Pending',                     // Status default
        'IT Dept'                      // Divisi (Dummy dulu)
      );

      // Parsing response
      var decodedData = jsonDecode(response);

      if (mounted) {
        setState(() => _isLoading = false);

        // Validasi response dari GoCloud (Biasanya return List/Map yg berisi ID)
        if (decodedData is List && decodedData.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data berhasil disimpan ke Cloud!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Kembali & trigger refresh
        } else {
          throw Exception("Gagal menyimpan: $response");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _qtyController.addListener(_calculateTotal);
    _priceController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Input: ${widget.monthName}"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel("Nama Barang"),
              TextFormField(
                controller: _itemController,
                validator: (val) => val!.isEmpty ? "Nama barang wajib diisi" : null,
                decoration: _inputDecor("Contoh: Laptop, Kertas A4"),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel("Jumlah (Qty)"),
                        TextFormField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          validator: (val) => val!.isEmpty ? "Wajib isi" : null,
                          decoration: _inputDecor("0"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel("Harga Satuan"),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          validator: (val) => val!.isEmpty ? "Wajib isi" : null,
                          decoration: _inputDecor("Rp 0", prefix: "Rp "),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Total Price Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    const Text("Total Estimasi", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      "Rp $_totalPrice",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitToCloud,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("KIRIM PENGAJUAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}