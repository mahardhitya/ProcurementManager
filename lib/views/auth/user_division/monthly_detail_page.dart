import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_request_page.dart';
import '../../../core/restapi.dart';
import '../../../core/config.dart';

class MonthlyDetailPage extends StatefulWidget {
  final String monthName;
  final int monthIndex;
  final String userDivision;

  const MonthlyDetailPage({
    super.key,
    required this.monthName,
    required this.monthIndex,
    required this.userDivision,
  });

  @override
  State<MonthlyDetailPage> createState() => _MonthlyDetailPageState();
}

class _MonthlyDetailPageState extends State<MonthlyDetailPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Fungsi untuk me-load data dari API
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Ambil user_id dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('user_id') ?? '';
      String userDivision =
          prefs.getString('division_name') ?? widget.userDivision;

      print('========== LOAD DATA DEBUG ==========');
      print('User ID: $userId');
      print('User Division from prefs: $userDivision');
      print('Month Name: ${widget.monthName}');
      print('Widget userDivision: ${widget.userDivision}');

      // Ambil semua procurement requests dari API
      String response = await _dataService.selectAll(
        AppConfig.token,
        'procumon', // Gunakan 'procumon' sesuai dengan insert
        'procurement_requests',
        AppConfig.appid,
      );

      print('API Response length: ${response.length}');
      print('API Response: $response');

      var jsonResponse = json.decode(response);

      // Handle response format: {"data": [...]} atau langsung [...]
      List requestData = [];
      if (jsonResponse is Map && jsonResponse['data'] != null) {
        requestData = jsonResponse['data'] as List;
        print('Response is Map with data field');
      } else if (jsonResponse is List) {
        requestData = jsonResponse;
        print('Response is direct List');
      } else {
        print('Response format unknown: ${jsonResponse.runtimeType}');
      }

      print('Total requests from API: ${requestData.length}');

      // Debug: Print semua item dari API
      for (var item in requestData) {
        print(
          'Item: ${item['item_name']}, Division: ${item['division_name']}, Month: ${item['month_name']}, Status: ${item['status']}',
        );
      }

      // Collect processed item keys (Approved/Rejected) to exclude their Pending versions
      Set<String> processedItemKeys = {};
      for (var item in requestData) {
        String status = item['status']?.toLowerCase() ?? '';
        if (status == 'approved' || status == 'rejected') {
          // Create unique key from item_name + division + month + date
          String key = '${item['item_name']}|${item['division_name']}|${item['month_name']}|${item['date']}';
          processedItemKeys.add(key);
          print('Processed item key: $key');
        }
      }

      // Filter berdasarkan divisi user dan bulan
      List<Map<String, dynamic>> filteredRequests = [];
      for (var item in requestData) {
        String itemDivision = item['division_name'] ?? '';
        String itemMonth = item['month_name'] ?? '';
        String itemStatus = item['status'] ?? 'Pending';
        String itemId = item['id'] ?? item['_id'] ?? '';

        print(
          'Checking: Division=$itemDivision vs $userDivision, Month=$itemMonth vs ${widget.monthName}',
        );

        // Skip items that are deleted or processed
        bool isDeleted = itemStatus.toLowerCase() == 'deleted' || 
                         itemStatus.toLowerCase() == 'processed';
        
        // Skip pending items that have a processed version (Approved/Rejected exists)
        String itemKey = '${item['item_name']}|$itemDivision|$itemMonth|${item['date']}';
        bool isPendingWithProcessedVersion = 
            itemStatus.toLowerCase() == 'pending' && processedItemKeys.contains(itemKey);

        // Filter berdasarkan divisi dan bulan
        if (itemDivision == userDivision &&
            itemMonth == widget.monthName &&
            !isDeleted &&
            !isPendingWithProcessedVersion) {
          print('MATCH FOUND: ${item['item_name']} (status: $itemStatus)');
          
          filteredRequests.add({
            'id': itemId,
            'item_name': item['item_name'] ?? 'Unknown',
            'quantity': int.tryParse(item['quantity']?.toString() ?? '0') ?? 0,
            'price': int.tryParse(item['price']?.toString() ?? '0') ?? 0,
            'total_price':
                int.tryParse(item['total_price']?.toString() ?? '0') ?? 0,
            'status': item['status'] ?? 'Pending',
            'date': item['date'] ?? '',
            'division': itemDivision,
            'rejection_reason': item['rejection_reason'] ?? '',
          });
        }
      }

      print('Filtered requests count: ${filteredRequests.length}');
      print('========== END DEBUG ==========');

      setState(() {
        _requests = filteredRequests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hitung total dari data bulan ini
    int totalItems = 0;
    int totalBudget = 0;
    for (var item in _requests) {
      totalItems += item['quantity'] as int;
      totalBudget += (item['quantity'] as int) * (item['price'] as int);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text("Pengajuan ${widget.monthName}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // Header Summary
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryCard(
                          "Total Item",
                          "$totalItems Pcs",
                          Icons.shopping_cart,
                          Colors.orange,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade200,
                        ),
                        _buildSummaryCard(
                          "Total Biaya",
                          "Rp ${_formatNumber(totalBudget)}",
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),

                  // List
                  Expanded(
                    child: _requests.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _requests.length,
                            itemBuilder: (context, index) {
                              final item = _requests[index];
                              return _buildRequestCard(item);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigasi ke Form Add, tunggu hasil baliknya
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddRequestPage(
                monthName: widget.monthName,
                userDivision: widget.userDivision,
              ),
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

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            "Belum ada pengajuan.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> item) {
    // Parsing status warna
    Color statusColor = Colors.orange;
    if (item['status'] == 'Approved') statusColor = Colors.green;
    if (item['status'] == 'Rejected') statusColor = Colors.red;

    // Hitung total
    int totalPrice = (item['quantity'] as int) * (item['price'] as int);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['item_name'] ?? 'No Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tanggal: ${item['date']}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    item['status'] ?? 'Pending',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Icon Edit dan Hapus (hanya untuk status Pending)
                if (item['status'] == 'Pending') ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: Colors.blue,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showEditDialog(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: Colors.red,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _deleteItem(item),
                  ),
                ],
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Kuantitas",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${item['quantity']} pcs",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Harga Satuan",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rp ${_formatNumber(item['price'])}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rp ${_formatNumber(totalPrice)}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Tampilkan alasan penolakan jika status Rejected
            if (item['status'] == 'Rejected' &&
                item['rejection_reason'] != null &&
                item['rejection_reason'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Alasan Penolakan:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['rejection_reason'].toString(),
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Fungsi untuk hapus item
  void _deleteItem(Map<String, dynamic> item) {
    _showDeleteConfirmation(item);
  }

  // Fungsi untuk edit item via API
  void _showEditDialog(Map<String, dynamic> item) {
    final TextEditingController nameController = TextEditingController(
      text: item['item_name'],
    );
    final TextEditingController quantityController = TextEditingController(
      text: item['quantity'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Pengajuan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nama Barang",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantity",
                border: OutlineInputBorder(),
                suffixText: "pcs",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newQuantity = int.tryParse(quantityController.text) ?? 0;

              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Nama barang tidak boleh kosong"),
                  ),
                );
                return;
              }

              if (newQuantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Quantity harus lebih dari 0")),
                );
                return;
              }

              Navigator.pop(context);

              try {
                // Update item_name via API
                await _dataService.updateId(
                  'item_name',
                  newName,
                  AppConfig.token,
                  'procumon',
                  'procurement_requests',
                  AppConfig.appid,
                  item['id'],
                );

                // Update quantity via API
                await _dataService.updateId(
                  'quantity',
                  newQuantity.toString(),
                  AppConfig.token,
                  'procumon',
                  'procurement_requests',
                  AppConfig.appid,
                  item['id'],
                );

                // Update total_price
                int newTotalPrice = newQuantity * (item['price'] as int);
                await _dataService.updateId(
                  'total_price',
                  newTotalPrice.toString(),
                  AppConfig.token,
                  'procumon',
                  'procurement_requests',
                  AppConfig.appid,
                  item['id'],
                );

                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pengajuan berhasil diperbarui"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal memperbarui: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // Konfirmasi hapus via API
  void _showDeleteConfirmation(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: Text(
          "Apakah Anda yakin ingin menghapus pengajuan \"${item['item_name']}\"?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                // Delete via API - update status ke 'Deleted'
                await _dataService.updateId(
                  'status',
                  'Deleted',
                  AppConfig.token,
                  'procumon',
                  'procurement_requests',
                  AppConfig.appid,
                  item['id'],
                );

                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pengajuan berhasil dihapus"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal menghapus: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
