import 'dart:convert';
import '../core/restapi.dart'; 

class BudgetService {
  final DataService _dataService = DataService();
  final String appid;

  BudgetService({required this.appid}); 

  // =======================================================================
  // HELPER FUNCTIONS (UTILITIES)
  // =======================================================================

  /// Mengambil ID secara aman dari berbagai format respon API
  String? getId(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      if (data.containsKey('inserted_id')) return data['inserted_id']?.toString();
      if (data.containsKey('_id')) return data['_id']?.toString();
      if (data.containsKey('id')) return data['id']?.toString();
      
      // Jika ID ada di dalam properti 'data'
      if (data.containsKey('data')) {
        return getId(data['data']);
      }
    }

    if (data is List && data.isNotEmpty) {
      final firstItem = data[0];
      if (firstItem is Map) {
        return firstItem['_id']?.toString() ?? firstItem['id']?.toString();
      }
    }

    return null;
  }

  /// Memparsing satu objek (Map) dari response JSON
  Map<String, dynamic>? _parseSingle(dynamic data) {
    if (data == null) return null;
    
    // Jika formatnya {"data": [...]}
    if (data is Map && data.containsKey('data')) {
      final listData = data['data'];
      if (listData is List && listData.isNotEmpty) {
        return Map<String, dynamic>.from(listData[0]);
      }
    }

    if (data is Map<String, dynamic>) return data;
    return null;
  }

  /// Memparsing list objek (List<Map>) dari response JSON
  List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data == null) return [];
    
    if (data is Map && data.containsKey('data')) {
      final listData = data['data'];
      if (listData is List) {
        return listData.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    }
    
    // Jika data langsung berupa List (jarang terjadi di API ini tapi untuk jaga-jaga)
    if (data is List) {
       return data.map((item) => Map<String, dynamic>.from(item)).toList();
    }

    return [];
  }

  // =======================================================================
  // FISCAL YEAR (TAHUN ANGGARAN)
  // =======================================================================

  Future<Map<String, dynamic>?> getFiscalYearByYear(int year) async {
    try {
      final response = await _dataService.selectWhere('fiscal_years', appid, 'year', year.toString());
      return _parseSingle(json.decode(response));
    } catch (e) {
      print("Error getFiscalYear: $e");
      return null;
    }
  }

  Future<String?> createFiscalYear(int year, {String status = 'Active'}) async {
    try {
      final response = await _dataService.insertFiscalYears(appid, year.toString(), status);
      final decoded = json.decode(response);
      
      // Coba ambil ID dari response insert
      String? id = getId(decoded);

      // Jika insert sukses tapi tidak return ID, cari manual
      if (id == null) {
        final existing = await getFiscalYearByYear(year);
        id = getId(existing);
      }
      return id;
    } catch (e) {
      print("Error createFiscalYear: $e");
      return null;
    }
  }

  // =======================================================================
  // MONTHLY BUDGET (ANGGARAN BULANAN)
  // =======================================================================

  Future<List<Map<String, dynamic>>> getMonthlyBudgets(String fiscalYearId) async {
    if (fiscalYearId.isEmpty || fiscalYearId == "null") return [];
    try {
      final response = await _dataService.selectWhere('monthly_budgets', appid, 'fiscal_year_id', fiscalYearId);
      return _parseList(json.decode(response));
    } catch (e) {
      print("Error getMonthlyBudgets: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getMonthlyBudget(String monthId) async {
    try {
      // Trim ID untuk keamanan
      final response = await _dataService.selectId('monthly_budgets', appid, monthId.trim());
      return _parseSingle(json.decode(response));
    } catch (e) {
      print("Error getMonthlyBudget: $e");
      return null;
    }
  }

  Future<String?> createMonthlyBudget({
    required String fiscalYearId,
    required String monthName,
    required int monthIndex,
    double revenue = 0,
    double expense = 0,
  }) async {
    try {
      final response = await _dataService.insertMonthlyBudgets(
        appid, 
        fiscalYearId, 
        monthName, 
        monthIndex.toString(), 
        revenue.toStringAsFixed(0), 
        expense.toStringAsFixed(0)
      );
      return getId(json.decode(response));
    } catch (e) {
      print("Error createMonthlyBudget: $e");
      return null;
    }
  }

  // --- LOGIC UPDATE REVENUE (PERBAIKAN UTAMA) ---
  Future<bool> updateMonthlyRevenue(String monthId, double revenue) async {
    final cleanId = monthId.trim(); // Bersihkan spasi
    print("DEBUG: Update Revenue. ID: $cleanId, Value: $revenue");

    try {
      // Pastikan return dari DataService.updateId adalah boolean atau dicek statusnya
      final result = await _dataService.updateId(
        'total_revenue', 
        revenue.toStringAsFixed(0), // Kirim sebagai string angka bulat
        'monthly_budgets', 
        appid, 
        cleanId
      );
      
      // Cek respon (tergantung implementasi DataService kamu, biasanya return bool)
      print("DEBUG: Hasil Update Revenue = $result");
      return result == true; 
    } catch (e) {
      print("Error updateMonthlyRevenue: $e");
      return false;
    }
  }

  Future<bool> updateMonthlyExpense(String monthId, double expense) async {
    return await _dataService.updateId(
      'total_expense', 
      expense.toStringAsFixed(0), 
      'monthly_budgets', 
      appid, 
      monthId.trim()
    );
  }

  // =======================================================================
  // PROCUREMENT REQUEST (PERMINTAAN BELANJA)
  // =======================================================================

  Future<List<Map<String, dynamic>>> getProcurementRequests(String monthlyBudgetId) async {
    final cleanId = monthlyBudgetId.trim();
    print("DEBUG: Mengambil Request dengan monthly_budget_id = '$cleanId'");

    try {
      final response = await _dataService.selectWhere('procurement_requests', appid, 'monthly_budget_id', cleanId);
      
      final result = _parseList(json.decode(response));
      print("DEBUG: Ditemukan ${result.length} data request.");
      
      if (result.isEmpty) {
        print("SARAN: Cek Database. Apakah kolom 'monthly_budget_id' isinya '$cleanId'? Atau masih nama bulan (cth: 'Januari')?");
      }

      return result;
    } catch (e) {
      print("Error getProcurementRequests: $e");
      return [];
    }
  }

  Future<bool> updateRequestStatus(String requestId, String status) async {
    print("DEBUG: Update Status Request $requestId jadi $status");
    return await _dataService.updateId('status', status, 'procurement_requests', appid, requestId.trim());
  }

  // --- HITUNG ULANG TOTAL PENGELUARAN ---
  Future<bool> recalculateMonthlyExpense(String monthlyBudgetId) async {
    try {
      print("DEBUG: Menghitung ulang expense untuk bulan $monthlyBudgetId");
      final requests = await getProcurementRequests(monthlyBudgetId);
      
      double total = 0;
      for (var request in requests) {
        // Hanya hitung yang statusnya 'Approved'
        if (request['status']?.toString().toLowerCase() == 'approved') {
          double val = double.tryParse(request['total_price']?.toString() ?? '0') ?? 0;
          total += val;
        }
      }
      
      print("DEBUG: Total Expense Baru = $total");
      return await updateMonthlyExpense(monthlyBudgetId, total);
    } catch (e) {
      print("Error recalculate: $e");
      return false;
    }
  }
}