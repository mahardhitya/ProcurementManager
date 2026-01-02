import 'package:flutter/material.dart';
import 'monthly_detail_page.dart';

class DashboardUser extends StatelessWidget {
  const DashboardUser({super.key});

  final List<String> months = const [
    "Januari", "Februari", "Maret", "April", "Mei", "Juni",
    "Juli", "Agustus", "September", "Oktober", "November", "Desember"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Background abu muda
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. HEADER MODERN (Sama seperti sebelumnya) ---
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF1E88E5)], // Biru Profesional
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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Halo, Divisi IT", style: TextStyle(color: Colors.white70, fontSize: 16)),
                            SizedBox(height: 5),
                            Text("Pengajuan Anggaran", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: const Icon(Icons.person, color: Colors.white),
                        )
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
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryInfo("Total Item", "12 Pcs", Icons.shopping_bag_outlined, Colors.orange),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        _buildSummaryInfo("Total Biaya", "450 Jt", Icons.attach_money, Colors.green),
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
                  const Text("Periode 2025", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  ListView.separated(
                    padding: const EdgeInsets.only(bottom: 30),
                    shrinkWrap: true, // Agar bisa discroll bareng parent
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: months.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
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
    bool isCurrentMonth = DateTime.now().month == index;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MonthlyDetailPage(monthName: monthName, monthIndex: index),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isCurrentMonth ? Border.all(color: Colors.blue, width: 2) : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Icon Kotak di Kiri
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCurrentMonth ? Colors.blue.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  index.toString().padLeft(2, '0'), // 01, 02, dst
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: isCurrentMonth ? Colors.blue : Colors.grey
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
                  Text(
                    monthName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  // Simulasi status (Nanti bisa diganti data real)
                  Text(
                    isCurrentMonth ? "Sedang Berjalan" : "Belum ada pengajuan",
                    style: TextStyle(
                      fontSize: 12, 
                      color: isCurrentMonth ? Colors.green : Colors.grey.shade500
                    ),
                  ),
                ],
              ),
            ),

            // Panah Kanan
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // Widget Helper: Info di Header
  Widget _buildSummaryInfo(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        )
      ],
    );
  }
}