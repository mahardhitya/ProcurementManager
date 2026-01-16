import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:procurement/core/config.dart';
import 'package:procurement/core/restapi.dart';
import 'package:procurement/models/monthly_budgets_model.dart';
import 'package:procurement/models/procurement_requests_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

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

  final List<String> divisions = const [
    "IT",
    "Marketing",
    "Operations",
    "Finance",
    "HR",
  ];

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _AdminHomeTab(months: months, onShowLogout: _showLogoutDialog),
          _AdminApprovalTab(months: months, divisions: divisions),
          _AdminBudgetingTab(divisions: divisions),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fact_check_outlined),
              activeIcon: Icon(Icons.fact_check),
              label: 'Approval',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Budgeting',
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== HOME TAB ====================
class _AdminHomeTab extends StatefulWidget {
  final List<String> months;
  final VoidCallback onShowLogout;

  const _AdminHomeTab({required this.months, required this.onShowLogout});

  @override
  State<_AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<_AdminHomeTab> {
  final DataService _svc = DataService();
  bool _isLoading = true;
  String _selectedMonth = "";
  List<MonthlyBudgetsModel> _budgets = [];
  List<ProcurementRequestsModel> _approvedRequests = [];
  List<ProcurementRequestsModel> _allRequests =
      []; // All requests for PDF export
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    int currentMonthIndex = DateTime.now().month - 1;
    _selectedMonth = widget.months[currentMonthIndex];
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Load monthly budgets
      final budgetResp = await _svc.selectAll(
        AppConfig.token,
        'procumon',
        'monthly_budgets',
        AppConfig.appid,
      );

      List budgetData = [];
      if (budgetResp != null && budgetResp.isNotEmpty) {
        try {
          final budgetJson = json.decode(budgetResp);
          if (budgetJson is Map && budgetJson['data'] != null) {
            budgetData = budgetJson['data'] as List;
          } else if (budgetJson is List) {
            budgetData = budgetJson;
          }
        } catch (e) {
          print('Error parsing budget JSON: $e');
        }
      }

      if (budgetData.isNotEmpty) {
        _budgets = budgetData
            .map(
              (d) => MonthlyBudgetsModel.fromJson(
                d as Map<String, dynamic>? ?? {},
              ),
            )
            .toList();
        _budgets.sort(
          (a, b) =>
              int.tryParse(
                a.month_index,
              )?.compareTo(int.tryParse(b.month_index) ?? 0) ??
              0,
        );
      } else {
        _budgets = _generateDummyBudgets();
      }

      // Load approved procurement requests for expense calculation
      final requestResp = await _svc.selectAll(
        AppConfig.token,
        'procumon',
        'procurement_requests',
        AppConfig.appid,
      );

      List requestData = [];
      if (requestResp != null && requestResp.isNotEmpty) {
        try {
          final requestJson = json.decode(requestResp);
          if (requestJson is Map && requestJson['data'] != null) {
            requestData = requestJson['data'] as List;
          } else if (requestJson is List) {
            requestData = requestJson;
          }
        } catch (e) {
          print('Error parsing request JSON: $e');
        }
      }

      _approvedRequests = [];
      _allRequests = [];
      for (var d in requestData) {
        try {
          final req = ProcurementRequestsModel.fromJson(
            d as Map<String, dynamic>? ?? {},
          );
          _allRequests.add(req); // Add to all requests
          if (req.status.toLowerCase() == 'approved') {
            _approvedRequests.add(req);
          }
        } catch (e) {
          print('Error parsing request: $e');
        }
      }
    } catch (e) {
      print('Error loading data: $e');
      if (_budgets.isEmpty) {
        _budgets = _generateDummyBudgets();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<MonthlyBudgetsModel> _generateDummyBudgets() {
    return List.generate(12, (i) {
      return MonthlyBudgetsModel(
        id: 'dummy-${i + 1}',
        fiscal_year_id: 'fy-2026',
        month_name: widget.months[i],
        month_index: '${i + 1}',
        total_revenue: '${(50 + (i * 10)) * 1000000}',
        total_expense: '${(30 + (i * 5)) * 1000000}',
      );
    });
  }

  MonthlyBudgetsModel? get _currentMonthBudget {
    try {
      return _budgets.firstWhere((b) => b.month_name == _selectedMonth);
    } catch (e) {
      return null;
    }
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000000) {
      return "${(amount / 1000000000).toStringAsFixed(1)}M";
    } else if (amount >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(0)}Jt";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(0)}K";
    }
    return amount.toString();
  }

  // Calculate expense from approved requests for selected month
  int get _expenseFromApproved {
    return _approvedRequests
        .where((req) => req.month_name == _selectedMonth)
        .fold(
          0,
          (sum, req) =>
              sum +
              (int.tryParse(req.total_price) ??
                  (double.tryParse(req.total_price)?.toInt() ?? 0)),
        );
  }

  @override
  Widget build(BuildContext context) {
    final budget = _currentMonthBudget;
    final revenue = budget != null
        ? int.tryParse(budget.total_revenue) ?? 0
        : 0;
    // Expense now comes from approved procurement requests
    final expense = _expenseFromApproved;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Color(0xFF1E88E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Admin Panel",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "ProcuMon",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/admin/input-revenue',
                                  ).then((_) => _loadData());
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: widget.onShowLogout,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.logout,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Summary Card
                Positioned(
                  bottom: -45,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildSummaryInfo(
                          "Pemasukan",
                          "${_formatCurrency(revenue)}",
                          Icons.trending_up,
                          Colors.green,
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.grey.shade200,
                        ),
                        _buildSummaryInfo(
                          "Pengeluaran",
                          "${_formatCurrency(expense)}",
                          Icons.trending_down,
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 65),

            // Month Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih Bulan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.months.length,
                      itemBuilder: (context, index) {
                        final month = widget.months[index];
                        final isSelected = month == _selectedMonth;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMonth = month),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue : Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                month,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pie Chart Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ringkasan $_selectedMonth",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildPieChartCard(revenue, expense),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Export PDF Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _exportToPdf,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text(
                    'Export Laporan ke PDF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard(int revenue, int expense) {
    final total = revenue + expense;
    final revenuePercent = total > 0 ? (revenue / total * 100) : 0.0;
    final expensePercent = total > 0 ? (expense / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: total == 0
                ? const Center(child: Text("Belum ada data"))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(
                          value: revenue.toDouble(),
                          title: '${revenuePercent.toStringAsFixed(0)}%',
                          color: Colors.green,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: expense.toDouble(),
                          title: '${expensePercent.toStringAsFixed(0)}%',
                          color: Colors.red,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(
                Colors.green,
                "Pemasukan",
                _currencyFormat.format(revenue),
              ),
              _buildLegendItem(
                Colors.red,
                "Pengeluaran",
                _currencyFormat.format(expense),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sisa Budget
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sisa Anggaran:",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  _currencyFormat.format(revenue - expense),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: (revenue - expense) >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // PDF Export Functionality
  Future<void> _exportToPdf() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final budget = _currentMonthBudget;
      final revenue = budget != null
          ? int.tryParse(budget.total_revenue) ?? 0
          : 0;
      final expense = _expenseFromApproved;
      final sisaAnggaran = revenue - expense;

      // Get requests for selected month - safe copy to avoid web issues
      final List<ProcurementRequestsModel> monthRequests = _getRequestsForMonth(
        _selectedMonth,
      );

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'LAPORAN PROCUREMENT',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Bulan $_selectedMonth ${DateTime.now().year}',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Summary Section
              pw.Text(
                'RINGKASAN ANGGARAN',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _buildPdfSummaryRow(
                      'Total Pemasukan',
                      _currencyFormat.format(revenue),
                      PdfColors.green,
                    ),
                    pw.Divider(color: PdfColors.grey300),
                    _buildPdfSummaryRow(
                      'Total Pengeluaran',
                      _currencyFormat.format(expense),
                      PdfColors.red,
                    ),
                    pw.Divider(color: PdfColors.grey300),
                    _buildPdfSummaryRow(
                      'Sisa Anggaran',
                      _currencyFormat.format(sisaAnggaran),
                      sisaAnggaran >= 0 ? PdfColors.green : PdfColors.red,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Items Table
              pw.Text(
                'DAFTAR PENGAJUAN BARANG',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              if (monthRequests.length == 0)
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Tidak ada data pengajuan untuk bulan ini',
                      style: const pw.TextStyle(color: PdfColors.grey),
                    ),
                  ),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(0.5),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1.5),
                    5: const pw.FlexColumnWidth(1.2),
                  },
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue100,
                      ),
                      children: [
                        _buildPdfTableHeader('No'),
                        _buildPdfTableHeader('Nama Barang'),
                        _buildPdfTableHeader('Qty'),
                        _buildPdfTableHeader('Harga'),
                        _buildPdfTableHeader('Total'),
                        _buildPdfTableHeader('Status'),
                      ],
                    ),
                    // Data Rows - using for loop to avoid web issues
                    ..._buildPdfTableRows(monthRequests),
                  ],
                ),

              pw.SizedBox(height: 24),

              // Status Summary
              pw.Text(
                'RINGKASAN STATUS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfStatusSummary(
                      'Disetujui',
                      _countByStatus(monthRequests, 'approved'),
                      PdfColors.green,
                    ),
                    _buildPdfStatusSummary(
                      'Ditolak',
                      _countByStatus(monthRequests, 'rejected'),
                      PdfColors.red,
                    ),
                    _buildPdfStatusSummary(
                      'Pending',
                      _countByStatus(monthRequests, 'pending'),
                      PdfColors.orange,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 32),

              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(top: 16),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Dicetak pada: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                    pw.Text(
                      'ProcuMon - Procurement Manager',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show print/share dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laporan_Procurement_$_selectedMonth.pdf',
      );
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfSummaryRow(String label, String value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildPdfTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildPdfStatusCell(String status) {
    PdfColor bgColor;
    PdfColor textColor = PdfColors.white;
    String displayText;

    switch (status.toLowerCase()) {
      case 'approved':
        bgColor = PdfColors.green;
        displayText = 'Disetujui';
        break;
      case 'rejected':
        bgColor = PdfColors.red;
        displayText = 'Ditolak';
        break;
      default:
        bgColor = PdfColors.orange;
        displayText = 'Pending';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          displayText,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  pw.Widget _buildPdfStatusSummary(String label, int count, PdfColor color) {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            '$count',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  // Helper method to count requests by status (avoids .where() issues on web)
  int _countByStatus(List<ProcurementRequestsModel> requests, String status) {
    int count = 0;
    try {
      final int len = requests.length;
      for (int i = 0; i < len; i++) {
        if (requests[i].status.toLowerCase() == status) {
          count++;
        }
      }
    } catch (e) {
      print('Error counting status: $e');
    }
    return count;
  }

  // Helper method to build PDF table rows (avoids .map() issues on web)
  List<pw.TableRow> _buildPdfTableRows(
    List<ProcurementRequestsModel> requests,
  ) {
    List<pw.TableRow> rows = [];
    try {
      final int len = requests.length;
      for (int i = 0; i < len; i++) {
        final req = requests[i];
        rows.add(
          pw.TableRow(
            children: [
              _buildPdfTableCell('${i + 1}'),
              _buildPdfTableCell(req.item_name),
              _buildPdfTableCell(req.quantity),
              _buildPdfTableCell(
                _currencyFormat.format(int.tryParse(req.price) ?? 0),
              ),
              _buildPdfTableCell(
                _currencyFormat.format(int.tryParse(req.total_price) ?? 0),
              ),
              _buildPdfStatusCell(req.status),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error building table rows: $e');
    }
    return rows;
  }

  // Helper method to get requests for a specific month (avoids iteration issues on web)
  List<ProcurementRequestsModel> _getRequestsForMonth(String month) {
    final List<ProcurementRequestsModel> result = [];
    try {
      final int len = _allRequests.length;
      for (int i = 0; i < len; i++) {
        final req = _allRequests[i];
        if (req.month_name == month) {
          result.add(req);
        }
      }
    } catch (e) {
      print('Error getting requests for month: $e');
    }
    return result;
  }
}

// ==================== APPROVAL TAB ====================
class _AdminApprovalTab extends StatefulWidget {
  final List<String> months;
  final List<String> divisions;

  const _AdminApprovalTab({required this.months, required this.divisions});

  @override
  State<_AdminApprovalTab> createState() => _AdminApprovalTabState();
}

class _AdminApprovalTabState extends State<_AdminApprovalTab> {
  final DataService _svc = DataService();
  bool _isLoading = true;
  String _selectedMonth = "";
  String _selectedDivision = "";
  List<ProcurementRequestsModel> _pendingRequests = [];
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    int currentMonthIndex = DateTime.now().month - 1;
    _selectedMonth = widget.months[currentMonthIndex];
    _selectedDivision = widget.divisions.first;
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final requestResp = await _svc.selectAll(
        AppConfig.token,
        'procumon',
        'procurement_requests',
        AppConfig.appid,
      );

      List requestData = [];
      if (requestResp != null && requestResp.isNotEmpty) {
        try {
          final requestJson = json.decode(requestResp);
          if (requestJson is Map && requestJson['data'] != null) {
            requestData = requestJson['data'] as List;
          } else if (requestJson is List) {
            requestData = requestJson;
          }
        } catch (e) {
          print('Error parsing JSON: $e');
        }
      }

      // Collect processed items
      Set<String> processedItemKeys = {};
      for (var item in requestData) {
        if (item == null) continue;
        String status = (item['status'] ?? '').toString().toLowerCase();
        if (status == 'approved' || status == 'rejected') {
          String key =
              '${item['item_name'] ?? ''}|${item['division_name'] ?? ''}|${item['month_name'] ?? ''}|${item['date'] ?? ''}';
          processedItemKeys.add(key);
        }
      }

      // Filter pending only
      _pendingRequests = [];
      for (var d in requestData) {
        if (d == null) continue;
        try {
          final req = ProcurementRequestsModel.fromJson(
            d as Map<String, dynamic>? ?? {},
          );
          if (req.status.toLowerCase() != 'pending') continue;
          String key =
              '${req.item_name}|${req.division_name}|${req.month_name}|${req.date}';
          if (!processedItemKeys.contains(key)) {
            _pendingRequests.add(req);
          }
        } catch (e) {
          print('Error parsing request: $e');
        }
      }
      _pendingRequests = _pendingRequests.reversed.toList();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ProcurementRequestsModel> get _filteredRequests {
    return _pendingRequests.where((req) {
      return req.month_name == _selectedMonth &&
          req.division_name == _selectedDivision;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Approval Pengajuan",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_filteredRequests.length} pengajuan menunggu",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Month Filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.months.length,
                    itemBuilder: (context, index) {
                      final month = widget.months[index];
                      final isSelected = month == _selectedMonth;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMonth = month),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              month,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Division Filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.divisions.length,
                    itemBuilder: (context, index) {
                      final div = widget.divisions[index];
                      final isSelected = div == _selectedDivision;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDivision = div),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orange
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              div,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRequests.length,
                    itemBuilder: (context, index) =>
                        _buildRequestCard(_filteredRequests[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Tidak ada pengajuan dari $_selectedDivision di bulan $_selectedMonth",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(ProcurementRequestsModel request) {
    final totalPrice = double.tryParse(request.total_price) ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  request.date,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.item_name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Qty: ${request.quantity}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.attach_money, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _currencyFormat.format(totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReject(request),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApprove(request),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Setujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(ProcurementRequestsModel request) async {
    final quantityController = TextEditingController(text: request.quantity);
    int? approvedQuantity;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Setujui Pengajuan'),
        content: StatefulBuilder(
          builder: (context, setState) {
            final currentQty = int.tryParse(quantityController.text) ?? 0;
            final unitPrice = double.tryParse(request.price) ?? 0;
            final newTotalPrice = currentQty * unitPrice;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item: ${request.item_name}'),
                const SizedBox(height: 8),
                Text('Harga Satuan: ${_currencyFormat.format(unitPrice)}'),
                const SizedBox(height: 16),
                const Text(
                  'Kuantitas Disetujui:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: currentQty > 0
                          ? () => setState(
                              () => quantityController.text = (currentQty - 1)
                                  .toString(),
                            )
                          : null,
                    ),
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (val) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: currentQty < int.parse(request.quantity)
                          ? () => setState(
                              () => quantityController.text = (currentQty + 1)
                                  .toString(),
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Diminta: ${request.quantity}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 16),
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
                        'Total Biaya:',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        _currencyFormat.format(newTotalPrice),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              approvedQuantity = int.tryParse(quantityController.text);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        if (approvedQuantity == null || approvedQuantity! <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kuantitas tidak valid'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final unitPrice = double.tryParse(request.price) ?? 0;
        final newTotalPrice = approvedQuantity! * unitPrice;

        await _svc.insertProcurementRequestsWithReason(
          AppConfig.appid,
          request.monthly_budget_id,
          request.user_id,
          request.item_name,
          approvedQuantity.toString(),
          request.price,
          newTotalPrice.toString(),
          'Approved',
          request.division_name,
          request.date,
          request.month_name,
          request.imange_path,
          '',
        );

        await _svc.updateId(
          'status',
          'processed',
          AppConfig.token,
          'procumon',
          'procurement_requests',
          AppConfig.appid,
          request.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengajuan berhasil disetujui'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleReject(ProcurementRequestsModel request) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Pengajuan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menolak pengajuan "${request.item_name}"?',
            ),
            const SizedBox(height: 16),
            const Text(
              'Alasan Penolakan: *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Masukkan alasan penolakan...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alasan penolakan wajib diisi'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _svc.insertProcurementRequestsWithReason(
          AppConfig.appid,
          request.monthly_budget_id,
          request.user_id,
          request.item_name,
          request.quantity,
          request.price,
          request.total_price,
          'Rejected',
          request.division_name,
          request.date,
          request.month_name,
          request.imange_path,
          reasonController.text.trim(),
        );

        await _svc.updateId(
          'status',
          'processed',
          AppConfig.token,
          'procumon',
          'procurement_requests',
          AppConfig.appid,
          request.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengajuan berhasil ditolak'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

// ==================== BUDGETING TAB ====================
class _AdminBudgetingTab extends StatefulWidget {
  final List<String> divisions;

  const _AdminBudgetingTab({required this.divisions});

  @override
  State<_AdminBudgetingTab> createState() => _AdminBudgetingTabState();
}

class _AdminBudgetingTabState extends State<_AdminBudgetingTab> {
  final DataService _svc = DataService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _incomeList = [];
  Map<String, int> _divisionBudgets = {};
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Controllers for new income
  final TextEditingController _incomeSourceController = TextEditingController();
  final TextEditingController _incomeAmountController = TextEditingController();

  // Controllers for budget allocation
  String _selectedDivision = "";
  final TextEditingController _budgetAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDivision = widget.divisions.first;
    _loadData();
  }

  @override
  void dispose() {
    _incomeSourceController.dispose();
    _incomeAmountController.dispose();
    _budgetAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load income data from API or use dummy
      // For now using dummy data
      _incomeList = [
        {'source': 'Sponsorship A', 'amount': 50000000, 'date': '2026-01-05'},
        {'source': 'Sponsorship B', 'amount': 30000000, 'date': '2026-01-10'},
        {'source': 'Dana Investor', 'amount': 100000000, 'date': '2026-01-15'},
      ];

      // Load division budgets from API
      await _loadDivisionBudgetsFromAPI();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDivisionBudgetsFromAPI() async {
    try {
      String response = await _svc.selectAll(
        AppConfig.token,
        'procumon',
        'division_budgets',
        AppConfig.appid,
      );

      var jsonResponse = json.decode(response);
      List budgetData = [];
      if (jsonResponse is Map && jsonResponse['data'] != null) {
        budgetData = jsonResponse['data'] as List;
      } else if (jsonResponse is List) {
        budgetData = jsonResponse;
      }

      // Initialize with default values
      Map<String, int> loadedBudgets = {
        'IT': 0,
        'Marketing': 0,
        'Operations': 0,
        'Finance': 0,
        'HR': 0,
      };

      // Update with data from API
      for (var budget in budgetData) {
        String divisionName = budget['division_name'] ?? '';
        int amount =
            int.tryParse(budget['allocated_budget']?.toString() ?? '0') ?? 0;
        if (loadedBudgets.containsKey(divisionName)) {
          loadedBudgets[divisionName] = amount;
        }
      }

      _divisionBudgets = loadedBudgets;
    } catch (e) {
      print('Error loading division budgets: $e');
      // Use default values if error
      _divisionBudgets = {
        'IT': 0,
        'Marketing': 0,
        'Operations': 0,
        'Finance': 0,
        'HR': 0,
      };
    }
  }

  int get _totalIncome =>
      _incomeList.fold(0, (sum, item) => sum + (item['amount'] as int));
  int get _totalAllocated =>
      _divisionBudgets.values.fold(0, (sum, val) => sum + val);
  int get _remainingBudget => _totalIncome - _totalAllocated;

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    value = value.replaceAll('.', '');
    final number = int.tryParse(value);
    if (number == null) return value;
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _addIncome() {
    if (_incomeSourceController.text.isEmpty ||
        _incomeAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi data pemasukan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amount =
        int.tryParse(_incomeAmountController.text.replaceAll('.', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _incomeList.add({
        'source': _incomeSourceController.text,
        'amount': amount,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
      _incomeSourceController.clear();
      _incomeAmountController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pemasukan berhasil ditambahkan'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _allocateBudget() async {
    final amount =
        int.tryParse(_budgetAmountController.text.replaceAll('.', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount >
        _remainingBudget + (_divisionBudgets[_selectedDivision] ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah melebihi sisa anggaran'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save to API
    try {
      // Check if budget for this division already exists
      String checkResponse = await _svc.selectWhere(
        AppConfig.token,
        'procumon',
        'division_budgets',
        AppConfig.appid,
        'division_name',
        _selectedDivision,
      );

      var checkData = json.decode(checkResponse);
      List existingBudgets = [];
      if (checkData is Map && checkData['data'] != null) {
        existingBudgets = checkData['data'] as List;
      } else if (checkData is List) {
        existingBudgets = checkData;
      }

      if (existingBudgets.isNotEmpty) {
        // Update existing budget
        String budgetId =
            existingBudgets[0]['id'] ?? existingBudgets[0]['_id'] ?? '';
        await _svc.updateId(
          'allocated_budget',
          amount.toString(),
          AppConfig.token,
          'procumon',
          'division_budgets',
          AppConfig.appid,
          budgetId,
        );
      } else {
        // Insert new budget
        await _svc.insertDivisionBudgets(
          AppConfig.appid,
          _selectedDivision,
          amount.toString(),
          '', // month_name - empty for overall budget
          DateTime.now().year.toString(),
        );
      }

      setState(() {
        _divisionBudgets[_selectedDivision] = amount;
        _budgetAmountController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Budget $_selectedDivision berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving budget: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan budget: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Budgeting",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Kelola anggaran dan budget divisi",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBudgetSummaryItem(
                        "Total Pemasukan",
                        _currencyFormat.format(_totalIncome),
                        Colors.green,
                      ),
                      _buildBudgetSummaryItem(
                        "Total Dialokasi",
                        _currencyFormat.format(_totalAllocated),
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _remainingBudget >= 0
                          ? Colors.blue.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Sisa Anggaran:",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _currencyFormat.format(_remainingBudget),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _remainingBudget >= 0
                                ? Colors.blue
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Income Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pemasukan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Add Income Form
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _incomeSourceController,
                          decoration: InputDecoration(
                            labelText: 'Sumber Pemasukan',
                            hintText: 'Contoh: Sponsorship, Investor',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.source),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _incomeAmountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Jumlah',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.attach_money),
                          ),
                          onChanged: (value) {
                            final formatted = _formatNumber(value);
                            if (formatted != value) {
                              _incomeAmountController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                  offset: formatted.length,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _addIncome,
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Pemasukan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Income List
                  ..._incomeList
                      .map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.arrow_downward,
                                  color: Colors.green.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['source'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      item['date'],
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _currencyFormat.format(item['amount']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Budget Allocation Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Alokasi Budget Divisi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Allocation Form
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedDivision,
                          decoration: InputDecoration(
                            labelText: 'Pilih Divisi',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.business),
                          ),
                          items: widget.divisions
                              .map(
                                (div) => DropdownMenuItem(
                                  value: div,
                                  child: Text(div),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedDivision = val;
                                _budgetAmountController.text = _formatNumber(
                                  _divisionBudgets[val]?.toString() ?? '0',
                                );
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _budgetAmountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Jumlah Budget',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(
                              Icons.account_balance_wallet,
                            ),
                          ),
                          onChanged: (value) {
                            final formatted = _formatNumber(value);
                            if (formatted != value) {
                              _budgetAmountController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                  offset: formatted.length,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _allocateBudget,
                            icon: const Icon(Icons.save),
                            label: const Text('Simpan Alokasi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Division Budget List
                  ...widget.divisions
                      .map(
                        (div) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.business,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  div,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                _currencyFormat.format(
                                  _divisionBudgets[div] ?? 0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
