import 'package:flutter/material.dart';
import '../../service/budget_service.dart';
import '../../utils/app_helpers.dart'; // Pastikan path ini sesuai struktur folder Anda
import '../../core/config.dart'; // Pastikan path ini sesuai

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // Menggunakan AppConfig dari config.dart
  final BudgetService _budgetService = BudgetService(appid: AppConfig.appid);
  
  int currentYear = DateTime.now().year;
  List<Map<String, dynamic>> monthlyData = [];
  bool isLoading = true;
  String? fiscalYearId;
  
  final List<String> monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Logika memuat data & sinkronisasi bulan (US-008 & Data Sync)
Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      print("=== MULAI LOAD DATA DASHBOARD ===");

      // ---------------------------------------------------------
      // STEP 1: URUS FISCAL YEAR (TAHUN ANGGARAN)
      // ---------------------------------------------------------
      var fiscalData = await _budgetService.getFiscalYearByYear(currentYear);
      fiscalYearId = _budgetService.getId(fiscalData);

      // Jika tidak ada, BUAT BARU
      if (fiscalYearId == null || fiscalYearId!.isEmpty) {
        print("DEBUG: Fiscal Year tidak ditemukan. Membuat baru untuk tahun $currentYear...");
        await _budgetService.createFiscalYear(currentYear);
        
        // PENTING: Ambil ulang dari DB untuk memastikan dapat ID-nya
        await Future.delayed(const Duration(milliseconds: 500)); // Jeda sebentar agar DB selesai simpan
        fiscalData = await _budgetService.getFiscalYearByYear(currentYear);
        fiscalYearId = _budgetService.getId(fiscalData);
      }

      print("DEBUG: FISCAL YEAR ID = $fiscalYearId");

      if (fiscalYearId == null) {
        throw Exception("Gagal mendapatkan Fiscal Year ID meski sudah dibuat.");
      }

      // ---------------------------------------------------------
      // STEP 2: URUS MONTHLY BUDGETS (BULANAN)
      // ---------------------------------------------------------
      final existingBudgets = await _budgetService.getMonthlyBudgets(fiscalYearId!);
      print("DEBUG: Ditemukan ${existingBudgets.length} bulan di Database.");

      List<Map<String, dynamic>> temp = [];

      for (int i = 0; i < 12; i++) {
        final name = monthNames[i];
        final idx = i + 1;

        // Cari apakah bulan ini ada di data yang kita download tadi
        var match = existingBudgets.firstWhere(
          (b) => b['month_index']?.toString() == idx.toString(),
          orElse: () => {},
        );

        String mId = '';
        double rev = 0;
        double exp = 0;

        // Jika bulan ditemukan di DB
        if (match.isNotEmpty) {
          mId = _budgetService.getId(match) ?? '';
          rev = double.tryParse(match['total_revenue']?.toString() ?? '0') ?? 0;
          exp = double.tryParse(match['total_expense']?.toString() ?? '0') ?? 0;
          print("DEBUG: Bulan $name ADA. ID: $mId");
        } 
        
        // Jika bulan TIDAK ditemukan atau ID-nya kosong (meski datanya ada)
        if (match.isEmpty || mId.isEmpty) {
          print("DEBUG: Bulan $name KOSONG/RUSAK. Membuat/Memperbaiki...");
          
          // Create bulan baru
          await _budgetService.createMonthlyBudget(
            fiscalYearId: fiscalYearId!,
            monthName: name,
            monthIndex: idx,
          );

          // TRICK: Kita tidak pakai ID dari respon create karena sering null.
          // Kita akan reload data nanti atau biarkan kosong dulu, 
          // user harus refresh manual jika otomatis gagal.
        }

        temp.add({
          'id': mId, // ID ini krusial
          'month': name,
          'index': idx,
          'revenue': rev,
          'expense': exp,
        });
      }
      
      // Jika ada bulan yang baru dibuat, kita perlu REFRESH listnya 
      // supaya ID-nya terisi benar dari database.
      bool adaYangKosong = temp.any((item) => item['id'] == '');
      if (adaYangKosong) {
        print("DEBUG: Ada ID bulan yang masih kosong. Reloading data dari DB...");
        // Panggil ulang ambil data bulan
        final reloadedBudgets = await _budgetService.getMonthlyBudgets(fiscalYearId!);
        
        // Update temp list dengan data yang baru direload
        for (var item in temp) {
          if (item['id'] == '') {
            var match = reloadedBudgets.firstWhere(
              (b) => b['month_index']?.toString() == item['index'].toString(),
              orElse: () => {},
            );
            if (match.isNotEmpty) {
               item['id'] = _budgetService.getId(match) ?? '';
               print("DEBUG: ID Bulan ${item['month']} berhasil diperbaiki jadi: ${item['id']}");
            }
          }
        }
      }

      if (mounted) setState(() => monthlyData = temp);

    } catch (e) {
      print("ERROR FATAL DASHBOARD: $e");
      if (mounted) AppHelpers.showSnackBar(context, "Error: $e", backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'), // US-032
            tooltip: 'Profile',
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Selector Tahun ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Periode Anggaran', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() => currentYear--);
                        _loadData();
                      },
                    ),
                    Text(
                      '$currentYear',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() => currentYear++);
                        _loadData();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // --- Grid View 12 Bulan (US-008) ---
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Tampilan 2 kolom
                        childAspectRatio: 1.3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: monthlyData.length,
                      itemBuilder: (context, index) {
                        final item = monthlyData[index];
                        return _buildMonthCard(item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Widget Card Bulan yang Sudah Diperbaiki (Fix InkWell/OnTap)
  Widget _buildMonthCard(Map<String, dynamic> item) {
    final revenue = item['revenue'] as double;
    final expense = item['expense'] as double;
    
    // Logic Warna (US-011): 
    // Hijau jika Surplus (Rev >= Exp), Merah jika Defisit (Exp > Rev), Abu jika kosong.
    Color bgColor = Colors.grey.shade100;
    Color statusColor = Colors.grey;

    if (revenue > 0 || expense > 0) {
      if (expense > revenue) {
        bgColor = Colors.red.shade50; // Defisit
        statusColor = Colors.red;
      } else {
        bgColor = Colors.green.shade50; // Surplus
        statusColor = Colors.green;
      }
    }

    // PERBAIKAN: Gunakan Material + InkWell + Ink agar klik terdeteksi
    return Material(
      color: Colors.transparent, 
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Navigasi ke Detail Bulan (US-012)
          final result = await Navigator.pushNamed(
            context, 
            '/admin/month-detail', // Pastikan route ini ada di main.dart
            arguments: {
              'monthId': item['id'],
              'month': item['month'],
              'year': currentYear,
              'fiscalYearId': fiscalYearId,
            }
          );

          // Jika kembali dari halaman detail (setelah approve/edit), refresh data
          if (result == true) {
            _loadData(); 
          }
        },
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3)),
            boxShadow: [
               BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Nama Bulan
              Text(
                item['month'], 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              
              // Info Revenue & Expense (US-010)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rowInfo('Pemasukan', revenue, Colors.green.shade700),
                  const SizedBox(height: 4),
                  _rowInfo('Pengeluaran', expense, Colors.red.shade700),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowInfo(String label, double val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          val > 0 ? AppHelpers.formatCurrency(val) : '-',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        )
      ],
    );
  }
}