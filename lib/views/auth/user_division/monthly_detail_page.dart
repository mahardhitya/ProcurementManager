import 'package:flutter/material.dart';
import 'package:procurement/core/config.dart';
import '../../../core/restapi.dart'; // Import DataService
import 'dart:convert';
import 'add_request_page.dart';

class MonthlyDetailPage extends StatefulWidget {
  final String monthName;
  final int monthIndex;

  const MonthlyDetailPage({super.key, required this.monthName, required this.monthIndex});

  @override
  State<MonthlyDetailPage> createState() => _MonthlyDetailPageState();
}

class _MonthlyDetailPageState extends State<MonthlyDetailPage> {
  late Future<List<dynamic>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Fungsi untuk me-refresh data dari server
  void _loadData() {
    setState(() {
      _requestsFuture = _fetchRequests();
    });
  }

  // CORE LOGIC: Fetch from GoCloud
  Future<List<dynamic>> _fetchRequests() async {
    final dataService = DataService();
    
    // PANGGILAN BARU (Lebih Pendek & Bersih)
    String response = await dataService.selectWhere(
      'procurement_requests', // Nama Collection
      'monthly_budget_id',    // Kolom yang dicari
      widget.monthName,       // Nilai (Contoh: "Januari")
      'asc'                   // Sort order (add the 4th argument)
    );

    // ... sisa kodingan decoding JSON di bawahnya tetap sama ...
    var decoded = jsonDecode(response);
    if (decoded is List) {
      return decoded;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text("Pengajuan ${widget.monthName}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Error State
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          // 3. Empty State
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          // 4. Data Loaded State
          final data = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return _buildRequestCard(item);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigasi ke Form Add, tunggu hasil baliknya
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddRequestPage(monthName: widget.monthName),
            ),
          );
          
          // Jika sukses simpan (result == true), refresh halaman ini
          if (result == true) {
            _loadData();
          }
        },
        label: const Text("Ajukan Barang"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Belum ada pengajuan.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> item) {
    // Parsing status warna
    Color statusColor = Colors.orange;
    if (item['status'] == 'Approved') statusColor = Colors.green;
    if (item['status'] == 'Rejected') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['item_name'] ?? 'No Name',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item['quantity']} pcs x Rp ${item['price']}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Total: Rp ${item['total_price']}",
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                item['status'] ?? 'Pending',
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}