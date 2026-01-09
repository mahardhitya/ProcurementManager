import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../service/budget_service.dart';
import '../../utils/app_helpers.dart';
import '../../core/config.dart'; 

class AdminMonthDetailPage extends StatefulWidget {
  const AdminMonthDetailPage({Key? key}) : super(key: key);

  @override
  State<AdminMonthDetailPage> createState() => _AdminMonthDetailPageState();
}

class _AdminMonthDetailPageState extends State<AdminMonthDetailPage> {

  final BudgetService _budgetService = BudgetService(appid: AppConfig.appid);
  
  bool isLoading = true;
  double revenue = 0;
  double totalExpenseApproved = 0;
  List<Map<String, dynamic>> procurementRequests = [];
  
  String? monthId;
  String? fiscalYearId;
  String monthName = '';
  int year = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isLoading) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        monthId = args['monthId']?.toString();
        fiscalYearId = args['fiscalYearId']?.toString();
        monthName = args['month'] ?? '';
        year = args['year'] ?? 0;
        
        // DEBUG: Cek apakah ID diterima dengan benar dari Dashboard
        print("DEBUG DETAIL: Menerima Month ID: '$monthId'");
        
        _loadData();
      }
    }
  }

  Future<void> _loadData() async {
    if (monthId == null || monthId!.isEmpty) {
      setState(() => isLoading = false);
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      // 1. Load data budget bulanan (untuk ambil revenue & expense terbaru)
      final budgetData = await _budgetService.getMonthlyBudget(monthId!);
      
      if (budgetData != null) {
        revenue = double.tryParse(budgetData['total_revenue']?.toString() ?? '0') ?? 0;
        totalExpenseApproved = double.tryParse(budgetData['total_expense']?.toString() ?? '0') ?? 0;
      }
      
      // 2. Load daftar request belanja
      procurementRequests = await _budgetService.getProcurementRequests(monthId!);
      
    } catch (e) {
      if(mounted) AppHelpers.showSnackBar(context, 'Error loading data: $e', backgroundColor: Colors.red);
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }

  // =======================================================================
  // LOGIC: UPDATE REVENUE (TARGET PEMASUKAN)
  // =======================================================================
  Future<void> _updateRevenue(double newRevenue) async {
    // Validasi ID sebelum kirim ke server
    if (monthId == null || monthId!.isEmpty) {
      AppHelpers.showSnackBar(context, 'Gagal: ID Bulan tidak valid (Kosong)', backgroundColor: Colors.red);
      return;
    }

    // Cek Warning jika Revenue baru < Pengeluaran yg sudah diapprove
    if (newRevenue < totalExpenseApproved) {
       if(mounted) AppHelpers.showSnackBar(context, 'Warning: Target lebih kecil dari pengeluaran!', backgroundColor: Colors.orange);
    }

    try {
      final success = await _budgetService.updateMonthlyRevenue(monthId!, newRevenue);
      if (success) {
        await _loadData(); // Refresh UI
        if(mounted) AppHelpers.showSnackBar(context, 'Target Pemasukan berhasil disimpan', backgroundColor: Colors.green);
      } else {
        if(mounted) AppHelpers.showSnackBar(context, 'Gagal menyimpan. Cek koneksi.', backgroundColor: Colors.red);
      }
    } catch (e) {
      print(e);
    }
  }

  // =======================================================================
  // LOGIC: APPROVE REQUEST
  // =======================================================================
  Future<void> _approveRequest(int index) async {
    final request = procurementRequests[index];
    
    // 1. Ambil ID Request dengan aman (Cek id dan _id)
    final requestId = request['id']?.toString() ?? request['_id']?.toString();
    
    // 2. Validasi ID
    if (requestId == null || requestId.isEmpty) {
      AppHelpers.showSnackBar(context, 'Error Fatal: Data ini tidak punya ID. Hapus dan buat ulang.', backgroundColor: Colors.red);
      return;
    }

    final itemPrice = double.tryParse(request['total_price']?.toString() ?? '0') ?? 0;
    
    // 3. Cek Defisit (Apakah expense akan melebihi revenue?)
    final potentialExpense = totalExpenseApproved + itemPrice;
    
    if (potentialExpense > revenue) {
      // Tampilkan Warning Dialog
      final confirm = await AppHelpers.showConfirmDialog(
        context,
        'Peringatan Budget Defisit',
        'Menyetujui item ini akan menyebabkan DEFISIT.\n\n'
        'Sisa Budget: ${AppHelpers.formatCurrency(revenue - totalExpenseApproved)}\n'
        'Harga Item: ${AppHelpers.formatCurrency(itemPrice)}\n\n'
        'Apakah Anda yakin ingin melanjutkan?',
        confirmText: 'Ya, Lanjutkan',
        isDanger: true,
      );
      
      if (confirm != true) return; // User membatalkan
    }

    // 4. Eksekusi Approval
    _performAction(requestId, 'Approved');
  }

  // =======================================================================
  // LOGIC: REJECT REQUEST
  // =======================================================================
  Future<void> _rejectRequest(int index) async {
    final request = procurementRequests[index];

    // 1. Validasi ID
    final requestId = request['id']?.toString() ?? request['_id']?.toString();
    if (requestId == null || requestId.isEmpty) {
      AppHelpers.showSnackBar(context, 'Error: ID Request tidak ditemukan.', backgroundColor: Colors.red);
      return;
    }
    
    final reasonController = TextEditingController();
    
    // 2. Dialog Alasan Penolakan
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Pengajuan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan alasan penolakan (opsional):'),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(hintText: 'Misal: Harga terlalu mahal'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 3. Eksekusi Reject
    _performAction(requestId, 'Rejected');
  }

  // =======================================================================
  // HELPER: EKSEKUSI KE SERVER
  // =======================================================================
  Future<void> _performAction(String requestId, String newStatus) async {
    AppHelpers.showLoadingDialog(context);

    try {
      // 1. Update Status
      final successStatus = await _budgetService.updateRequestStatus(requestId, newStatus);
      
      if (successStatus) {
        // 2. Hitung Ulang Total Expense (PENTING AGAR DATA KONSISTEN)
        await _budgetService.recalculateMonthlyExpense(monthId!);
        
        // 3. Refresh UI
        await _loadData();
        
        if(mounted) {
          AppHelpers.hideLoadingDialog(context);
          AppHelpers.showSnackBar(context, 'Status berhasil diubah: $newStatus', backgroundColor: Colors.green);
        }
      } else {
        throw Exception("Gagal update status di server");
      }
    } catch (e) {
      if(mounted) {
        AppHelpers.hideLoadingDialog(context);
        AppHelpers.showSnackBar(context, 'Error: $e', backgroundColor: Colors.red);
      }
    }
  }

  // --- DIALOG EDIT REVENUE ---
  void _showEditRevenueDialog() {
    final tempController = TextEditingController(text: revenue.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Target Pemasukan'),
        content: TextField(
          controller: tempController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Nominal (Rupiah)',
            prefixText: 'Rp ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(tempController.text) ?? 0;
              _updateRevenue(val);
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = revenue - totalExpenseApproved;
    // Persentase pemakaian
    final usagePercent = revenue == 0 ? 0.0 : (totalExpenseApproved / revenue);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Return true agar dashboard refresh
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('$monthName $year'),
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
        ),
        body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CARD RINGKASAN ---
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Target Pemasukan', style: TextStyle(fontSize: 14)),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                onPressed: _showEditRevenueDialog,
                                tooltip: 'Ubah Target',
                              )
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              AppHelpers.formatCurrency(revenue),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                          const Divider(),
                          _summaryRow('Total Approved', totalExpenseApproved, Colors.red),
                          const SizedBox(height: 8),
                          _summaryRow('Sisa Budget', balance, balance >= 0 ? Colors.blue : Colors.red),
                          
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: usagePercent > 1 ? 1 : usagePercent,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppHelpers.getProgressColor(usagePercent * 100)
                            ),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Terpakai ${(usagePercent * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Daftar Pengajuan (Request)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // --- LIST REQUEST ---
                  if (procurementRequests.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('Belum ada pengajuan')))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: procurementRequests.length,
                      itemBuilder: (context, index) {
                        final req = procurementRequests[index];
                        final status = req['status']?.toString() ?? 'Pending';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(left: BorderSide(color: AppConstants.getStatusColor(status), width: 5)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(req['item_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Chip(
                                        label: Text(req['division_name'] ?? 'Divisi', style: const TextStyle(fontSize: 10, color: Colors.white)),
                                        backgroundColor: Colors.blue.shade400,
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${req['quantity']} x ${AppHelpers.formatCurrency(double.tryParse(req['price'].toString()) ?? 0)}'),
                                  Text(
                                    'Total: ${AppHelpers.formatCurrency(double.tryParse(req['total_price'].toString()) ?? 0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text('Status: $status', style: TextStyle(color: AppConstants.getStatusColor(status), fontWeight: FontWeight.bold)),
                                      const Spacer(),
                                      
                                      // TOMBOL AKSI (Hanya jika Pending)
                                      if (status.toLowerCase() == 'pending') ...[
                                        IconButton(
                                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                                          onPressed: () => _approveRequest(index),
                                          tooltip: 'Setuju',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                                          onPressed: () => _rejectRequest(index),
                                          tooltip: 'Tolak',
                                        ),
                                      ]
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                ],
              ),
            ),
      ),
    );
  }

  Widget _summaryRow(String label, double val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          AppHelpers.formatCurrency(val),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}