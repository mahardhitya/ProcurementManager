import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:procurement/core/config.dart';
import 'package:procurement/core/restapi.dart';
import 'package:procurement/models/monthly_budgets_model.dart';
import 'package:procurement/models/procurement_requests_model.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DataService _svc = DataService();
  bool _loading = true;
  List<MonthlyBudgetsModel> _budgets = [];
  List<ProcurementRequestsModel> _pendingRequests = [];
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Load monthly budgets - gunakan 'procumon' sesuai dengan insert
      final budgetResp = await _svc.selectAll(
        AppConfig.token,
        'procumon', // FIXED: Gunakan 'procumon' bukan AppConfig.project
        'monthly_budgets',
        AppConfig.appid,
      );
      print('Budget Response: $budgetResp'); // Debug
      final budgetJson = json.decode(budgetResp);

      // Handle response format: {"data": [...]} atau langsung [...]
      List budgetData = [];
      if (budgetJson is Map && budgetJson['data'] != null) {
        budgetData = budgetJson['data'] as List;
      } else if (budgetJson is List) {
        budgetData = budgetJson;
      }

      if (budgetData.isNotEmpty) {
        _budgets = budgetData
            .map((d) => MonthlyBudgetsModel.fromJson(d))
            .toList();
        // Sort by month index
        _budgets.sort(
          (a, b) =>
              int.parse(a.month_index).compareTo(int.parse(b.month_index)),
        );
      } else {
        // Generate dummy data untuk demo jika database kosong
        _budgets = _generateDummyBudgets();
      }

      // Load pending procurement requests - gunakan 'procumon' sesuai dengan insert
      final requestResp = await _svc.selectAll(
        AppConfig.token,
        'procumon', // FIXED: Gunakan 'procumon' bukan AppConfig.project
        'procurement_requests',
        AppConfig.appid,
      );
      print('========== ADMIN LOAD REQUESTS ==========');
      print('Request Response: $requestResp');
      final requestJson = json.decode(requestResp);
      print('Request JSON type: ${requestJson.runtimeType}');

      // Handle response format: {"data": [...]} atau langsung [...]
      List requestData = [];
      if (requestJson is Map && requestJson['data'] != null) {
        requestData = requestJson['data'] as List;
        print('Data from Map["data"]: ${requestData.length} items');
      } else if (requestJson is List) {
        requestData = requestJson;
        print('Data from direct List: ${requestData.length} items');
      }

      print('Total Request Data: ${requestData.length}');

      // Debug: Print semua item
      for (var item in requestData) {
        print(
          'Item: ${item['item_name']}, Status: ${item['status']}, Division: ${item['division_name']}',
        );
      }

      if (requestData.isNotEmpty) {
        // First, collect all processed items (Approved/Rejected) to exclude their pending versions
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

        // Filter pending requests, excluding those that have been processed
        _pendingRequests = requestData
            .map((d) => ProcurementRequestsModel.fromJson(d))
            .where((req) {
              if (req.status.toLowerCase() != 'pending') return false;
              
              // Check if this pending item has a processed version
              String key = '${req.item_name}|${req.division_name}|${req.month_name}|${req.date}';
              if (processedItemKeys.contains(key)) {
                print('Excluding pending item (already processed): ${req.item_name}');
                return false;
              }
              return true;
            })
            .toList();
        // Sort by newest first (assuming id is sequential)
        _pendingRequests = _pendingRequests.reversed.toList();
        print('Pending requests after filter: ${_pendingRequests.length}');
      }
      print('========== END ADMIN LOAD ==========');
    } catch (e) {
      print('Error loading data: $e');
      // Jika error, tampilkan dummy budgets saja
      if (_budgets.isEmpty) {
        _budgets = _generateDummyBudgets();
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  List<MonthlyBudgetsModel> _generateDummyBudgets() {
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni'];
    return List.generate(6, (i) {
      return MonthlyBudgetsModel(
        id: 'dummy-${i + 1}',
        fiscal_year_id: 'fy-2026',
        month_name: months[i],
        month_index: '${i + 1}',
        total_revenue: '${(50 + (i * 10)) * 1000000}', // 50jt - 100jt
        total_expense: '${(30 + (i * 5)) * 1000000}', // 30jt - 55jt
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/admin/input-revenue',
              ).then((_) => _loadData());
            },
            tooltip: 'Input Pemasukan',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chart Section
                    _buildChartCard(),
                    const SizedBox(height: 24),

                    // Pending Requests Section
                    _buildPendingRequestsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChartCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pemasukan vs Pengeluaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: _budgets.isEmpty
                  ? const Center(child: Text('Belum ada data anggaran'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxY(),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final month = _budgets[groupIndex].month_name;
                              final value = rod.toY;
                              return BarTooltipItem(
                                '$month\n${_currencyFormat.format(value)}',
                                const TextStyle(color: Colors.white),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < _budgets.length) {
                                  final month =
                                      _budgets[value.toInt()].month_name;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      month.substring(0, 3),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${(value / 1000000).toStringAsFixed(0)}jt',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: true),
                        barGroups: _buildBarGroups(),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // Legend di bawah chart
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Pemasukan'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.red, 'Pengeluaran'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  double _getMaxY() {
    double max = 0;
    for (var budget in _budgets) {
      final revenue = double.tryParse(budget.total_revenue) ?? 0;
      final expense = double.tryParse(budget.total_expense) ?? 0;
      if (revenue > max) max = revenue;
      if (expense > max) max = expense;
    }
    return max * 1.2; // Add 20% padding
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(_budgets.length, (index) {
      final budget = _budgets[index];
      final revenue = double.tryParse(budget.total_revenue) ?? 0;
      final expense = double.tryParse(budget.total_expense) ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: revenue,
            color: Colors.green,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: expense,
            color: Colors.red,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPendingRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pengajuan Menunggu Persetujuan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_pendingRequests.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_pendingRequests.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _pendingRequests.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada pengajuan yang menunggu',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pendingRequests.length,
                itemBuilder: (context, index) {
                  final request = _pendingRequests[index];
                  return _buildPendingRequestCard(request);
                },
              ),
      ],
    );
  }

  Widget _buildPendingRequestCard(ProcurementRequestsModel request) {
    final totalPrice = double.tryParse(request.total_price) ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/admin/approval',
            arguments: request,
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(12),
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
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PENDING',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    request.division_name,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.item_name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Qty: ${request.quantity}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
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
              const SizedBox(height: 12),
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
      ),
    );
  }

  Future<void> _handleApprove(ProcurementRequestsModel request) async {
    final quantityController = TextEditingController(text: request.quantity);
    int? approvedQuantity;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
                          ? () {
                              setState(() {
                                quantityController.text = (currentQty - 1)
                                    .toString();
                              });
                            }
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
                          ? () {
                              setState(() {
                                quantityController.text = (currentQty + 1)
                                    .toString();
                              });
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Diminta: ${request.quantity}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
        // Validate approved quantity
        if (approvedQuantity == null || approvedQuantity! <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kuantitas tidak valid'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Calculate new total price based on approved quantity
        final unitPrice = double.tryParse(request.price) ?? 0;
        final newTotalPrice = approvedQuantity! * unitPrice;

        print('Approving request ID: ${request.id}');
        print(
          'Approved quantity: $approvedQuantity, New total: $newTotalPrice',
        );

        // WORKAROUND: Karena API update tidak berfungsi, gunakan insert baru
        // Data baru akan punya status Approved, data lama tetap Pending
        // Filter di _loadData() akan exclude pending yang sudah ada versi processed
        
        // Step 1: Insert data baru dengan status Approved
        final insertResult = await _svc.insertProcurementRequestsWithReason(
          AppConfig.appid,
          request.monthly_budget_id,
          request.user_id, // Keep original user_id
          request.item_name,
          approvedQuantity.toString(),
          request.price,
          newTotalPrice.toString(),
          'Approved',
          request.division_name,
          request.date,
          request.month_name,
          request.imange_path,
          '', // rejection_reason kosong untuk approved
        );
        print('Insert approved data result: $insertResult');

        // Step 2: Coba soft delete data lama - jika gagal, filter di UI
        final deleteResult = await _svc.updateId(
          'status',
          'processed', // Mark as processed instead of deleted
          AppConfig.token,
          'procumon',
          'procurement_requests',
          AppConfig.appid,
          request.id,
        );
        print('Mark old data as processed: $deleteResult');

        // Update monthly budget (kurangi saldo)
        final budget = _budgets.firstWhere(
          (b) => b.id == request.monthly_budget_id,
          orElse: () => MonthlyBudgetsModel(
            id: '',
            fiscal_year_id: '',
            month_name: '',
            month_index: '',
            total_revenue: '0',
            total_expense: '0',
          ),
        );

        if (budget.id.isNotEmpty) {
          final currentExpense = double.tryParse(budget.total_expense) ?? 0;
          final newExpense = currentExpense + newTotalPrice;

          await _svc.updateId(
            'total_expense',
            newExpense.toString(),
            AppConfig.token,
            'procumon',
            'monthly_budgets',
            AppConfig.appid,
            budget.id,
          );
        }

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
            SnackBar(
              content: Text('Gagal menyetujui pengajuan: $e'),
              backgroundColor: Colors.red,
            ),
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
        print('Rejecting request ID: ${request.id}');
        final rejectionReason = reasonController.text.trim();

        // WORKAROUND: Karena API update tidak berfungsi, gunakan insert baru
        // Filter di _loadData() akan exclude pending yang sudah ada versi processed
        
        // Step 1: Insert data baru dengan status Rejected
        final insertResult = await _svc.insertProcurementRequestsWithReason(
          AppConfig.appid,
          request.monthly_budget_id,
          request.user_id, // Keep original user_id
          request.item_name,
          request.quantity,
          request.price,
          request.total_price,
          'Rejected',
          request.division_name,
          request.date,
          request.month_name,
          request.imange_path,
          rejectionReason,
        );
        print('Insert rejected data result: $insertResult');

        // Step 2: Coba soft delete data lama (update API might fail, filtering handles it)
        final deleteResult = await _svc.updateId(
          'status',
          'processed',
          AppConfig.token,
          'procumon',
          'procurement_requests',
          AppConfig.appid,
          request.id,
        );
        print('Mark old data as processed: $deleteResult');

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
            SnackBar(
              content: Text('Gagal menolak pengajuan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
