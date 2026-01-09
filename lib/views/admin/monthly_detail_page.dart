import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:procurement/core/config.dart';
import 'package:procurement/core/restapi.dart';
import 'package:procurement/models/monthly_budgets_model.dart';
import 'package:procurement/models/procurement_requests_model.dart';

class MonthlyDetailPage extends StatefulWidget {
  final MonthlyBudgetsModel budget;

  const MonthlyDetailPage({super.key, required this.budget});

  @override
  State<MonthlyDetailPage> createState() => _MonthlyDetailPageState();
}

class _MonthlyDetailPageState extends State<MonthlyDetailPage> {
  List<ProcurementRequestsModel> _requests = [];
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
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final svc = DataService();
      final resp = await svc.selectWhere(
        'procurement_requests',
        AppConfig.appid,
        'monthly_budget_id',
        widget.budget.id,
      );
      final data = json.decode(resp);

      if (data is List) {
        final requests = data.map((r) => ProcurementRequestsModel.fromJson(r)).toList();
        requests.sort((a, b) => b.id.compareTo(a.id)); // Most recent first

        setState(() {
          _requests = requests;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading requests: $e');
      setState(() => _loading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  double _calculateBudgetUsage() {
    final revenue = double.tryParse(widget.budget.total_revenue) ?? 0.0;
    final expense = double.tryParse(widget.budget.total_expense) ?? 0.0;
    if (revenue == 0) return 0;
    return (expense / revenue).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final monthIndex = int.tryParse(widget.budget.month_index) ?? 0;
    final monthName = monthIndex < _monthNames.length ? _monthNames[monthIndex] : 'Bulan';
    final revenue = double.tryParse(widget.budget.total_revenue) ?? 0.0;
    final expense = double.tryParse(widget.budget.total_expense) ?? 0.0;
    final remaining = revenue - expense;
    final budgetUsage = _calculateBudgetUsage();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Text('Detail $monthName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
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
                          'Ringkasan Anggaran',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(height: 12),

                        // Revenue
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Pemasukan:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            Text(
                              'Rp${revenue.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Expense
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Pengeluaran:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            Text(
                              'Rp${expense.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Remaining
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sisa Budget:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            Text(
                              'Rp${remaining.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: remaining >= 0 ? Colors.green : Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: budgetUsage,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              budgetUsage >= 0.8 ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(budgetUsage * 100).toStringAsFixed(1)}% budget terpakai',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Requests List
                  const Text(
                    'Daftar Pengajuan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_requests.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(Icons.inbox, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada pengajuan',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final req = _requests[index];
                        return _buildRequestCard(req);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildRequestCard(ProcurementRequestsModel request) {
    final price = double.tryParse(request.price) ?? 0.0;
    final quantity = double.tryParse(request.quantity) ?? 0.0;
    final totalPrice = price * quantity;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.item_name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        request.division_name,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusLabel(request.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(request.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Qty: $quantity', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              Text('Harga: Rp${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                'Rp${totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13),
              ),
            ],
          ),

          // Rejection reason if rejected
          if (request.status.toLowerCase() == 'rejected' && request.rejection_reason.isNotEmpty)
            ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alasan Penolakan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 4),
                    Text(
                      request.rejection_reason,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}
