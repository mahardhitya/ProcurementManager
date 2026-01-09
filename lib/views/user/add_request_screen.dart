import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:procurement/core/config.dart';
import 'package:procurement/core/restapi.dart';

class AddRequestScreen extends StatefulWidget {
  final String monthlyBudgetId;
  final String userId;
  final String divisionName;

  const AddRequestScreen({
    super.key,
    required this.monthlyBudgetId,
    required this.userId,
    required this.divisionName,
  });

  @override
  State<AddRequestScreen> createState() => _AddRequestScreenState();
}

class _AddRequestScreenState extends State<AddRequestScreen> {
  final TextEditingController _itemName = TextEditingController();
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _price = TextEditingController();
  bool _loading = false;

  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _quantity.addListener(_calculateTotal);
    _price.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    final qty = double.tryParse(_quantity.text) ?? 0;
    final price = double.tryParse(_price.text) ?? 0;
    setState(() => _totalPrice = qty * price);
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

  Future<void> _submitRequest() async {
    final itemName = _itemName.text.trim();
    final quantity = _quantity.text.trim();
    final price = _price.text.trim();

    // Validasi
    if (itemName.isEmpty) {
      _showToast('Nama barang tidak boleh kosong');
      return;
    }
    if (quantity.isEmpty || double.tryParse(quantity) == null) {
      _showToast('Kuantitas harus berupa angka');
      return;
    }
    if (price.isEmpty || double.tryParse(price) == null) {
      _showToast('Harga harus berupa angka');
      return;
    }

    setState(() => _loading = true);

    try {
      final svc = DataService();
      final body = {
        'monthly_budget_id': widget.monthlyBudgetId,
        'user_id': widget.userId,
        'division_name': widget.divisionName,
        'item_name': itemName,
        'quantity': quantity,
        'price': price,
        'total_price': _totalPrice.toStringAsFixed(0),
        'status': 'Pending',
        'rejection_reason': '',
      };

      final resp = await svc.insertData('procurement_requests', AppConfig.appid, body);
      final insertData = json.decode(resp);

      if (insertData is Map && insertData.containsKey('id')) {
        _showSuccessToast('Pengajuan berhasil dibuat!');
        if (!mounted) return;
        Navigator.pop(context, true); // Return true to refresh list
      } else {
        _showToast('Pengajuan gagal, coba lagi');
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
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text('Buat Pengajuan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Pengajuan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Divisi: ${widget.divisionName}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nama Barang
            const Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _itemName,
              decoration: InputDecoration(
                hintText: 'Contoh: Monitor 24 inch',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kuantitas
            const Text('Kuantitas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Contoh: 5',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Harga Satuan
            const Text('Harga Satuan (Rp)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Contoh: 1500000',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Total Price Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Harga:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rp${_totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _loading ? null : _submitRequest,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Ajukan Pengajuan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _itemName.dispose();
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }
}
