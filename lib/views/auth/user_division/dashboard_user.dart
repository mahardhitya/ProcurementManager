import 'package:flutter/material.dart';
import 'monthly_detail_page.dart';
import 'profile_page.dart';
import 'notification_page.dart';

class DashboardUser extends StatefulWidget {
  final String userDivision;

  const DashboardUser({super.key, required this.userDivision});

  // Data dummy untuk semua bulan (dipindah ke class utama)
  static final Map<String, List<Map<String, dynamic>>> _dummyData = {
    "Januari": [
      {
        "item_name": "Laptop HP",
        "quantity": 5,
        "price": 8000000,
        "status": "Approved",
        "date": "2025-01-05",
        "division": "IT",
      },
      {
        "item_name": "Mouse Wireless",
        "quantity": 10,
        "price": 150000,
        "status": "Approved",
        "date": "2025-01-10",
        "division": "IT",
      },
      {
        "item_name": "Banner Promosi",
        "quantity": 5,
        "price": 500000,
        "status": "Approved",
        "date": "2025-01-12",
        "division": "Marketing",
      },
      {
        "item_name": "Brosur A4",
        "quantity": 1000,
        "price": 150000,
        "status": "Pending",
        "date": "2025-01-18",
        "division": "Marketing",
      },
    ],
    "Februari": [
      {
        "item_name": "Monitor 24 inch",
        "quantity": 6,
        "price": 2500000,
        "status": "Approved",
        "date": "2025-02-03",
        "division": "IT",
      },
      {
        "item_name": "Headset Gaming",
        "quantity": 3,
        "price": 800000,
        "status": "Approved",
        "date": "2025-02-20",
        "division": "Marketing",
      },
      {
        "item_name": "Spanduk Event",
        "quantity": 8,
        "price": 350000,
        "status": "Pending",
        "date": "2025-02-25",
        "division": "Marketing",
      },
    ],
    "Maret": [
      {
        "item_name": "SSD 1TB",
        "quantity": 10,
        "price": 1500000,
        "status": "Approved",
        "date": "2025-03-05",
        "division": "IT",
      },
      {
        "item_name": "RAM 16GB",
        "quantity": 8,
        "price": 900000,
        "status": "Approved",
        "date": "2025-03-12",
        "division": "IT",
      },
      {
        "item_name": "Katalog Produk",
        "quantity": 500,
        "price": 200000,
        "status": "Approved",
        "date": "2025-03-15",
        "division": "Marketing",
      },
      {
        "item_name": "Roll Up Banner",
        "quantity": 4,
        "price": 450000,
        "status": "Pending",
        "date": "2025-03-22",
        "division": "Marketing",
      },
    ],
    "April": [
      {
        "item_name": "Printer Laser",
        "quantity": 2,
        "price": 3500000,
        "status": "Approved",
        "date": "2025-04-08",
        "division": "Operations",
      },
      {
        "item_name": "UPS 1000VA",
        "quantity": 5,
        "price": 1800000,
        "status": "Pending",
        "date": "2025-04-22",
        "division": "IT",
      },
      {
        "item_name": "X-Banner",
        "quantity": 10,
        "price": 250000,
        "status": "Approved",
        "date": "2025-04-10",
        "division": "Marketing",
      },
      {
        "item_name": "Stiker Brand",
        "quantity": 2000,
        "price": 300000,
        "status": "Pending",
        "date": "2025-04-18",
        "division": "Marketing",
      },
    ],
    "Mei": [
      {
        "item_name": "Proyektor",
        "quantity": 1,
        "price": 5000000,
        "status": "Pending",
        "date": "2025-05-05",
        "division": "Marketing",
      },
      {
        "item_name": "Poster A3",
        "quantity": 300,
        "price": 250000,
        "status": "Approved",
        "date": "2025-05-15",
        "division": "Marketing",
      },
      {
        "item_name": "Switch 24 Port",
        "quantity": 2,
        "price": 4500000,
        "status": "Approved",
        "date": "2025-05-20",
        "division": "IT",
      },
    ],
    "Juni": [
      {
        "item_name": "NAS Storage 4TB",
        "quantity": 1,
        "price": 8000000,
        "status": "Approved",
        "date": "2025-06-03",
        "division": "IT",
      },
      {
        "item_name": "Cooling Pad",
        "quantity": 12,
        "price": 250000,
        "status": "Approved",
        "date": "2025-06-10",
        "division": "Operations",
      },
      {
        "item_name": "Kartu Nama",
        "quantity": 500,
        "price": 200000,
        "status": "Approved",
        "date": "2025-06-14",
        "division": "Marketing",
      },
      {
        "item_name": "Goodie Bag Event",
        "quantity": 100,
        "price": 150000,
        "status": "Pending",
        "date": "2025-06-22",
        "division": "Marketing",
      },
    ],
    "Juli": [
      {
        "item_name": "External HDD 2TB",
        "quantity": 6,
        "price": 1100000,
        "status": "Approved",
        "date": "2025-07-05",
        "division": "IT",
      },
      {
        "item_name": "Power Bank",
        "quantity": 10,
        "price": 300000,
        "status": "Approved",
        "date": "2025-07-20",
        "division": "Marketing",
      },
      {
        "item_name": "Backdrop Event",
        "quantity": 3,
        "price": 800000,
        "status": "Pending",
        "date": "2025-07-25",
        "division": "Marketing",
      },
    ],
    "Agustus": [
      {
        "item_name": "Tablet Android",
        "quantity": 4,
        "price": 3500000,
        "status": "Pending",
        "date": "2025-08-05",
        "division": "Marketing",
      },
      {
        "item_name": "Smartwatch",
        "quantity": 3,
        "price": 2000000,
        "status": "Approved",
        "date": "2025-08-15",
        "division": "Operations",
      },
      {
        "item_name": "LED Display",
        "quantity": 2,
        "price": 4000000,
        "status": "Approved",
        "date": "2025-08-18",
        "division": "Marketing",
      },
      {
        "item_name": "Charger Fast Charging",
        "quantity": 15,
        "price": 150000,
        "status": "Approved",
        "date": "2025-08-22",
        "division": "IT",
      },
    ],
    "September": [
      {
        "item_name": "Motherboard",
        "quantity": 3,
        "price": 2500000,
        "status": "Approved",
        "date": "2025-09-05",
        "division": "IT",
      },
      {
        "item_name": "CPU Intel i7",
        "quantity": 3,
        "price": 5000000,
        "status": "Approved",
        "date": "2025-09-10",
        "division": "IT",
      },
      {
        "item_name": "Neon Box",
        "quantity": 2,
        "price": 3500000,
        "status": "Approved",
        "date": "2025-09-12",
        "division": "Marketing",
      },
      {
        "item_name": "Flyer Promosi",
        "quantity": 5000,
        "price": 400000,
        "status": "Pending",
        "date": "2025-09-20",
        "division": "Marketing",
      },
    ],
    "Oktober": [
      {
        "item_name": "Server Rack",
        "quantity": 1,
        "price": 15000000,
        "status": "Pending",
        "date": "2025-10-05",
        "division": "IT",
      },
      {
        "item_name": "Kabel Network Cat6",
        "quantity": 100,
        "price": 50000,
        "status": "Approved",
        "date": "2025-10-12",
        "division": "Operations",
      },
      {
        "item_name": "Merchandise Kaos",
        "quantity": 200,
        "price": 100000,
        "status": "Approved",
        "date": "2025-10-15",
        "division": "Marketing",
      },
      {
        "item_name": "Mug Custom",
        "quantity": 150,
        "price": 50000,
        "status": "Pending",
        "date": "2025-10-22",
        "division": "Marketing",
      },
    ],
    "November": [
      {
        "item_name": "CCTV IP Camera",
        "quantity": 8,
        "price": 1500000,
        "status": "Approved",
        "date": "2025-11-05",
        "division": "Operations",
      },
      {
        "item_name": "DVR 16 Channel",
        "quantity": 1,
        "price": 3500000,
        "status": "Approved",
        "date": "2025-11-10",
        "division": "Operations",
      },
      {
        "item_name": "Kalender Promosi",
        "quantity": 300,
        "price": 250000,
        "status": "Approved",
        "date": "2025-11-12",
        "division": "Marketing",
      },
      {
        "item_name": "Souvenir Pulpen",
        "quantity": 500,
        "price": 75000,
        "status": "Pending",
        "date": "2025-11-20",
        "division": "Marketing",
      },
    ],
    "Desember": [
      {
        "item_name": "Antivirus Enterprise",
        "quantity": 50,
        "price": 500000,
        "status": "Approved",
        "date": "2025-12-10",
        "division": "IT",
      },
      {
        "item_name": "Standing Banner",
        "quantity": 6,
        "price": 400000,
        "status": "Approved",
        "date": "2025-12-12",
        "division": "Marketing",
      },
      {
        "item_name": "Nota Penjualan",
        "quantity": 1000,
        "price": 350000,
        "status": "Pending",
        "date": "2025-12-18",
        "division": "Marketing",
      },
    ],
  };

  // Getter untuk mengakses data dari luar class
  static Map<String, List<Map<String, dynamic>>> getDummyData() {
    return _dummyData;
  }

  // Method untuk filter data berdasarkan divisi
  static Map<String, List<Map<String, dynamic>>> getDataByDivision(
    String division,
  ) {
    Map<String, List<Map<String, dynamic>>> filteredData = {};

    _dummyData.forEach((month, items) {
      List<Map<String, dynamic>> filteredItems = items
          .where((item) => item['division'] == division)
          .toList();

      if (filteredItems.isNotEmpty) {
        filteredData[month] = filteredItems;
      }
    });

    return filteredData;
  }

  // Method untuk menambahkan data baru
  static void addNewRequest(String monthName, Map<String, dynamic> newRequest) {
    if (_dummyData.containsKey(monthName)) {
      _dummyData[monthName]!.add(newRequest);
    } else {
      _dummyData[monthName] = [newRequest];
    }
  }

  // Method untuk update quantity item
  static bool updateRequestQuantity(
    String monthName,
    String itemName,
    int newQuantity,
  ) {
    if (_dummyData.containsKey(monthName)) {
      final items = _dummyData[monthName]!;
      for (var item in items) {
        if (item['item_name'] == itemName) {
          if (newQuantity > 0) {
            item['quantity'] = newQuantity;
            return true;
          } else {
            // Jika quantity 0 atau negatif, hapus item
            items.remove(item);
            return true;
          }
        }
      }
    }
    return false;
  }

  // Method untuk update item (nama barang dan quantity)
  static bool updateRequestItem(
    String monthName,
    String oldItemName,
    String newItemName,
    int newQuantity,
  ) {
    if (_dummyData.containsKey(monthName)) {
      final items = _dummyData[monthName]!;
      for (var item in items) {
        if (item['item_name'] == oldItemName) {
          item['item_name'] = newItemName;
          item['quantity'] = newQuantity;
          return true;
        }
      }
    }
    return false;
  }

  // Method untuk hapus item
  static bool deleteRequest(String monthName, String itemName) {
    if (_dummyData.containsKey(monthName)) {
      final items = _dummyData[monthName]!;
      final initialLength = items.length;
      items.removeWhere((item) => item['item_name'] == itemName);
      return items.length < initialLength;
    }
    return false;
  }

  // Hitung jumlah notifikasi belum dibaca (Pending & Rejected) untuk divisi tertentu
  static int getUnreadNotificationCount([String? division]) {
    int count = 0;
    _dummyData.forEach((month, items) {
      for (var item in items) {
        // Filter berdasarkan divisi jika diberikan
        if (division != null && item['division'] != division) continue;

        if (item['status'] == 'Pending' || item['status'] == 'Rejected') {
          count++;
        }
      }
    });
    return count;
  }

  @override
  State<DashboardUser> createState() => _DashboardUserState();
}

class _DashboardUserState extends State<DashboardUser> {
  final List<String> months = const [
    "Januari",
    "Februari",
    "Maret",
    "April",
    "Mei",
    "Juni",
    "Juli",
    "Agustus",
    "September",
    "Oktober",
    "November",
    "Desember",
  ];

  // Hitung total item dan total biaya dari semua bulan untuk divisi user
  Map<String, dynamic> _calculateYearlyTotal() {
    int totalItems = 0;
    int totalBudget = 0;

    DashboardUser._dummyData.forEach((month, items) {
      for (var item in items) {
        // Filter hanya untuk divisi user
        if (item['division'] == widget.userDivision) {
          totalItems += item['quantity'] as int;
          totalBudget += (item['quantity'] as int) * (item['price'] as int);
        }
      }
    });

    return {'totalItems': totalItems, 'totalBudget': totalBudget};
  }

  // Method untuk refresh data
  void _refreshData() {
    setState(() {
      // Force rebuild untuk update total
    });
  }

  @override
  Widget build(BuildContext context) {
    final yearlyTotal = _calculateYearlyTotal();
    final totalItems = yearlyTotal['totalItems'] as int;
    final totalBudget = yearlyTotal['totalBudget'] as int;

    // Format angka dengan pemisah ribuan
    String formatCurrency(int amount) {
      if (amount >= 1000000000) {
        return "${(amount / 1000000000).toStringAsFixed(1)}M";
      } else if (amount >= 1000000) {
        return "${(amount / 1000000).toStringAsFixed(0)}Jt";
      } else if (amount >= 1000) {
        return "${(amount / 1000).toStringAsFixed(0)}K";
      }
      return amount.toString();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Background abu muda
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF1565C0),
                        Color(0xFF1E88E5),
                      ], // Biru Profesional
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Halo, Divisi ${widget.userDivision}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "ProcuMon",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Icon Notifikasi dengan badge
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NotificationPage(
                                          userDivision: widget.userDivision,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                // Badge notifikasi belum dibaca
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        DashboardUser.getUnreadNotificationCount(
                                          widget.userDivision,
                                        ).toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Icon Profil
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfilePage(
                                      userDivision: widget.userDivision,
                                    ),
                                  ),
                                );
                              },
                              child: const CircleAvatar(
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // KARTU RINGKASAN (Floating Card)
                Positioned(
                  bottom: -40,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryInfo(
                          "Total Item",
                          "$totalItems Pcs",
                          Icons.shopping_bag_outlined,
                          Colors.orange,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade200,
                        ),
                        _buildSummaryInfo(
                          "Total Biaya",
                          formatCurrency(totalBudget),
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60), // Jarak agar list tidak tertutup header
            // --- 2. LIST BULAN (PERSEGI PANJANG) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Periode 2025",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  ListView.separated(
                    padding: const EdgeInsets.only(bottom: 30),
                    shrinkWrap: true, // Agar bisa discroll bareng parent
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: months.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return _buildListItem(context, months[index], index + 1);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Helper: Item List Persegi Panjang
  Widget _buildListItem(BuildContext context, String monthName, int index) {
    // Hitung jumlah pengajuan per bulan dari dummy data
    int requestCount = DashboardUser._dummyData[monthName]?.length ?? 0;

    // Warna biru konsisten untuk semua bulan
    const Color blueColor = Color(0xFF1565C0);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MonthlyDetailPage(
                  monthName: monthName,
                  monthIndex: index,
                  userDivision: widget.userDivision,
                ),
              ),
            );
            // Refresh data setelah kembali dari monthly detail page
            _refreshData();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: blueColor.withOpacity(0.1),
          highlightColor: blueColor.withOpacity(0.05),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Icon Kotak di Kiri
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: blueColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: blueColor, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        index.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: blueColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Teks Tengah
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              monthName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: blueColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: blueColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                requestCount.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: blueColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              requestCount > 0
                                  ? Icons.check_circle_outline
                                  : Icons.calendar_today_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "$requestCount pengajuan",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Panah Kanan
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget Helper: Info di Header
  Widget _buildSummaryInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
