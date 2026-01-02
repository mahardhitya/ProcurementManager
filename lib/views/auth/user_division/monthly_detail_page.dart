import 'package:flutter/material.dart';
import 'add_request_page.dart';
import 'dashboard_user.dart'; // Import untuk akses data dummy

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Fungsi untuk me-load data dummy
  void _loadData() {
    setState(() {
      // Ambil data dari DashboardUser dan filter berdasarkan divisi
      final dummyData = DashboardUser.getDummyData();
      final monthData = dummyData[widget.monthName] ?? [];
      // Filter hanya data untuk divisi user
      _requests = monthData
          .where((item) => item['division'] == widget.userDivision)
          .toList();
    });
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
      ),
      body: Column(
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
                Container(width: 1, height: 40, color: Colors.grey.shade200),
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
          ],
        ),
      ),
    );
  }

  // Fungsi untuk kurangi quantity
  void _decreaseQuantity(Map<String, dynamic> item) {
    int currentQty = item['quantity'] as int;
    if (currentQty > 1) {
      // Update quantity
      bool success = DashboardUser.updateRequestQuantity(
        widget.monthName,
        item['item_name'],
        currentQty - 1,
      );
      if (success) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Quantity berhasil dikurangi")),
        );
      }
    } else {
      // Jika quantity 1, tanya apakah mau hapus
      _showDeleteConfirmation(item);
    }
  }

  // Fungsi untuk tambah quantity
  void _increaseQuantity(Map<String, dynamic> item) {
    int currentQty = item['quantity'] as int;
    bool success = DashboardUser.updateRequestQuantity(
      widget.monthName,
      item['item_name'],
      currentQty + 1,
    );
    if (success) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quantity berhasil ditambah")),
      );
    }
  }

  // Fungsi untuk hapus item
  void _deleteItem(Map<String, dynamic> item) {
    _showDeleteConfirmation(item);
  }

  // Fungsi untuk edit item
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
            onPressed: () {
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

              bool success = DashboardUser.updateRequestItem(
                widget.monthName,
                item['item_name'],
                newName,
                newQuantity,
              );

              Navigator.pop(context);

              if (success) {
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Pengajuan berhasil diperbarui"),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Gagal memperbarui pengajuan")),
                );
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // Konfirmasi hapus
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
            onPressed: () {
              Navigator.pop(context);
              bool success = DashboardUser.deleteRequest(
                widget.monthName,
                item['item_name'],
              );
              if (success) {
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Pengajuan berhasil dihapus"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
