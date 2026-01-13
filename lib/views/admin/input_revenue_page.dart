import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:procurement/core/config.dart';
import 'package:procurement/core/restapi.dart';
import 'package:procurement/models/fiscal_years_model.dart';

class InputRevenuePage extends StatefulWidget {
  const InputRevenuePage({super.key});

  @override
  State<InputRevenuePage> createState() => _InputRevenuePageState();
}

class _InputRevenuePageState extends State<InputRevenuePage> {
  final DataService _svc = DataService();
  final TextEditingController _revenueController = TextEditingController();

  String _selectedFiscalYearId = '';
  String _selectedMonth = 'Januari';
  List<FiscalYearsModel> _fiscalYears = [];
  bool _loading = false;
  bool _loadingFiscalYears = true;

  final List<String> _months = [
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
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _loadFiscalYears();
  }

  Future<void> _loadFiscalYears() async {
    setState(() => _loadingFiscalYears = true);
    try {
      final resp = await _svc.selectAll(
        AppConfig.token,
        AppConfig.project,
        'fiscal_years',
        AppConfig.appid,
      );
      final data = json.decode(resp);

      if (data is List && data.isNotEmpty) {
        _fiscalYears = data.map((d) => FiscalYearsModel.fromJson(d)).toList();
        // Prioritize active fiscal year
        _fiscalYears.sort((a, b) {
          if (a.status.toLowerCase() == 'active') return -1;
          if (b.status.toLowerCase() == 'active') return 1;
          return 0;
        });
        if (_fiscalYears.isNotEmpty) {
          _selectedFiscalYearId = _fiscalYears[0].id;
        }
      } else {
        // Generate dummy fiscal years jika database kosong
        _fiscalYears = _generateDummyFiscalYears();
        if (_fiscalYears.isNotEmpty) {
          _selectedFiscalYearId = _fiscalYears[0].id;
        }
      }
    } catch (e) {
      print('Error loading fiscal years: $e');
      // Jika error, gunakan data dummy
      _fiscalYears = _generateDummyFiscalYears();
      if (_fiscalYears.isNotEmpty) {
        _selectedFiscalYearId = _fiscalYears[0].id;
      }
    } finally {
      setState(() => _loadingFiscalYears = false);
    }
  }

  List<FiscalYearsModel> _generateDummyFiscalYears() {
    return [
      FiscalYearsModel(id: 'fy-2026', year: '2026', status: 'Active'),
      FiscalYearsModel(id: 'fy-2025', year: '2025', status: 'Inactive'),
    ];
  }

  Future<void> _saveRevenue() async {
    final revenue = _revenueController.text.trim();

    if (revenue.isEmpty) {
      _showToast('Masukkan jumlah pemasukan');
      return;
    }

    final revenueValue = double.tryParse(
      revenue.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (revenueValue == null || revenueValue <= 0) {
      _showToast('Jumlah pemasukan tidak valid');
      return;
    }

    if (_selectedFiscalYearId.isEmpty) {
      _showToast('Pilih tahun anggaran terlebih dahulu');
      return;
    }

    setState(() => _loading = true);

    try {
      // Check if monthly budget already exists
      final monthIndex = (_months.indexOf(_selectedMonth) + 1).toString();
      final checkResp = await _svc.selectAll(
        AppConfig.token,
        AppConfig.project,
        'monthly_budgets',
        AppConfig.appid,
      );
      final checkData = json.decode(checkResp);

      String? existingBudgetId;
      if (checkData is List) {
        for (var budget in checkData) {
          if (budget['fiscal_year_id'] == _selectedFiscalYearId &&
              budget['month_index'] == monthIndex) {
            existingBudgetId = budget['id'];
            break;
          }
        }
      }

      if (existingBudgetId != null) {
        // Update existing budget
        await _svc.updateId(
          'total_revenue',
          revenueValue.toString(),
          AppConfig.token,
          AppConfig.project,
          'monthly_budgets',
          AppConfig.appid,
          existingBudgetId,
        );
        _showSuccessToast('Pemasukan berhasil diperbarui');
      } else {
        // Create new monthly budget
        await _svc.insertMonthlyBudgets(
          AppConfig.token,
          AppConfig.project,
          AppConfig.appid,
          _selectedFiscalYearId,
          _selectedMonth,
          monthIndex,
          revenueValue.toString(),
        );
        _showSuccessToast('Pemasukan berhasil ditambahkan');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showToast('Gagal menyimpan pemasukan: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccessToast(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Input Pemasukan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loadingFiscalYears
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan Total Pemasukan/Budget untuk Bulan Tertentu',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Fiscal Year Dropdown
                  const Text(
                    'Tahun Anggaran',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedFiscalYearId.isEmpty
                        ? null
                        : _selectedFiscalYearId,
                    items: _fiscalYears.map((fy) {
                      return DropdownMenuItem(
                        value: fy.id,
                        child: Row(
                          children: [
                            Text(fy.year),
                            const SizedBox(width: 8),
                            if (fy.status.toLowerCase() == 'active')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedFiscalYearId = val ?? ''),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Month Dropdown
                  const Text(
                    'Bulan',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    items: _months.map((month) {
                      return DropdownMenuItem(value: month, child: Text(month));
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedMonth = val ?? 'Januari'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Revenue Input
                  const Text(
                    'Total Pemasukan/Budget',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _revenueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 50000000',
                      prefixText: 'Rp ',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      // Auto format as currency
                      final numValue = double.tryParse(
                        value.replaceAll(RegExp(r'[^0-9]'), ''),
                      );
                      if (numValue != null) {
                        // Keep cursor position
                        final selection = _revenueController.selection;
                        _revenueController.value = TextEditingValue(
                          text: numValue.toStringAsFixed(0),
                          selection: selection,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan jumlah tanpa titik atau koma',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _saveRevenue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Simpan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _revenueController.dispose();
    super.dispose();
  }
}
