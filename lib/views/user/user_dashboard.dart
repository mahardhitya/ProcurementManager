import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:procurement/core/config.dart';
import 'package:procurement/core/restapi.dart';
import 'package:procurement/models/monthly_budgets_model.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  List<MonthlyBudgetsModel> _monthlyBudgets = [];
  bool _loading = true;
  final List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _loadMonthlyBudgets();
  }

  Future<void> _loadMonthlyBudgets() async {
    try {
      final svc = DataService();
      final resp = await svc.getAll('monthly_budgets', AppConfig.appid);
      final data = json.decode(resp);

      if (data is List) {
        final budgets = data.map((b) => MonthlyBudgetsModel.fromJson(b)).toList();
        budgets.sort((a, b) => int.parse(a.month_index).compareTo(int.parse(b.month_index)));

        setState(() {
          _monthlyBudgets = budgets;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading monthly budgets: $e');
      setState(() => _loading = false);
    }
  }

  bool _isSurplus(MonthlyBudgetsModel budget) {
    final revenue = double.tryParse(budget.total_revenue) ?? 0.0;
    final expense = double.tryParse(budget.total_expense) ?? 0.0;
    return revenue >= expense;
  }

  Color _getCardColor(MonthlyBudgetsModel budget) {
    final revenue = double.tryParse(budget.total_revenue) ?? 0.0;
    if (revenue == 0.0) return Colors.grey.shade200;
    return _isSurplus(budget) ? Colors.green.shade100 : Colors.red.shade100;
  }

  Color _getIndicatorColor(MonthlyBudgetsModel budget) {
    final revenue = double.tryParse(budget.total_revenue) ?? 0.0;
    if (revenue == 0.0) return Colors.grey.shade400;
    return _isSurplus(budget) ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text('Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => Navigator.pushNamed(context, '/add-request'),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ajukan Pembelian',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pilih bulan untuk melihat status pengajuan',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tekan tombol + untuk membuat pengajuan baru',
                          style: TextStyle(color: Colors.blue, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 12 Month Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final budget = _monthlyBudgets.isNotEmpty && index < _monthlyBudgets.length
                          ? _monthlyBudgets[index]
                          : null;

                      return GestureDetector(
                        onTap: budget != null
                            ? () => Navigator.pushNamed(
                                  context,
                                  '/monthly-detail',
                                  arguments: budget,
                                )
                            : null,
                        child: _buildMonthCard(index, budget),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthCard(int monthIndex, MonthlyBudgetsModel? budget) {
    final monthName = _monthNames[monthIndex];
    final revenue = budget != null ? double.tryParse(budget.total_revenue) ?? 0.0 : 0.0;
    final expense = budget != null ? double.tryParse(budget.total_expense) ?? 0.0 : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: budget != null ? _getCardColor(budget) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: budget != null ? _getIndicatorColor(budget) : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  monthName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                ),
                if (budget != null)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getIndicatorColor(budget),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 8),

            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                children: [
                  const TextSpan(text: 'Pemasukan: '),
                  TextSpan(
                    text: 'Rp${revenue.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                children: [
                  const TextSpan(text: 'Pengeluaran: '),
                  TextSpan(
                    text: 'Rp${expense.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ),
            ),
            const Spacer(),

            if (budget != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: _isSurplus(budget) ? Colors.green.shade200 : Colors.red.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isSurplus(budget) ? 'Surplus' : 'Defisit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _isSurplus(budget) ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Kosong',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              )
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
