// ignore_for_file: non_constant_identifier_names

import 'package:http/http.dart' as http;
import 'config.dart'; // Pastikan path ini benar sesuai struktur folder Anda

class DataService {
  
  // =======================================================================
  // 1. HELPER REQUESTS (DENGAN LOGGING LENGKAP)
  // =======================================================================

  /// Helper untuk POST (Insert)
  Future<String> _postRequest(String endpoint, Map<String, String> body) async {
    // Bersihkan URL
    String uri = '${AppConfig.baseUrl}/$endpoint'.replaceAll(RegExp(r'\s+'), '');
    
    // Tambahkan kredensial wajib
    body['token'] = AppConfig.token;
    body['project'] = AppConfig.project;

    try {
      final response = await http.post(Uri.parse(uri), body: body);
      return response.body;
    } catch (e) {
      return '{"error": "Exception", "message": "$e"}';
    }
  }

  /// Helper untuk GET (Select)
  Future<String> _getRequest(String uri) async {
    try {
      final String cleanUri = uri.replaceAll(RegExp(r'\s+'), '');
      // print("DEBUG API GET: $cleanUri"); // Uncomment jika ingin lihat log GET
      
      final response = await http.get(Uri.parse(cleanUri));
      return response.body;
    } catch (e) {
      print("API ERROR: $e");
      return '[]';
    }
  }

  /// Helper untuk PUT (Update) - FOKUS UTAMA PERBAIKAN
  Future<bool> _putRequest(String endpoint, Map<String, String> body) async {
    String uri = '${AppConfig.baseUrl}/$endpoint'.replaceAll(RegExp(r'\s+'), '');
    
    body['token'] = AppConfig.token;
    body['project'] = AppConfig.project;

    print("DEBUG API: Mengirim PUT ke -> $endpoint");

    try {
      // PERBAIKAN: Menambahkan Header
      final response = await http.put(
        Uri.parse(uri), 
        body: body,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded"
        }
      );
      
      print("DEBUG API: Status -> ${response.statusCode}");
      
      if (response.statusCode == 200) {
        return !response.body.toLowerCase().contains("error");
      }
      return false;
    } catch (e) {
      print("DEBUG API: Crash -> $e");
      return false;
    }
  }
  /// Helper untuk DELETE (Remove)
  Future<bool> _deleteRequest(String uri) async {
    try {
      final String cleanUri = uri.replaceAll(RegExp(r'\s+'), '');
      final response = await http.delete(Uri.parse(cleanUri));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // =======================================================================
  // 2. FUNGSI INSERT (CREATE)
  // =======================================================================

  Future insertDivisions(String appid, String name, String code) async {
    return _postRequest('insert', {
      'collection': 'divisions',
      'appid': appid,
      'name': name,
      'code': code
    });
  }

  Future insertUsers(String appid, String name, String email, String password, String role, String division_id) async {
    return _postRequest('insert', {
      'collection': 'users',
      'appid': appid,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'division_id': division_id
    });
  }

  Future insertFiscalYears(String appid, String year, String status) async {
    return _postRequest('insert', {
      'collection': 'fiscal_years',
      'appid': appid,
      'year': year,
      'status': status
    });
  }

  Future insertMonthlyBudgets(String appid, String fiscal_year_id, String month_name, String month_index, String total_revenue, String total_expense) async {
    return _postRequest('insert', {
      'collection': 'monthly_budgets',
      'appid': appid,
      'fiscal_year_id': fiscal_year_id,
      'month_name': month_name,
      'month_index': month_index,
      'total_revenue': total_revenue,
      'total_expense': total_expense
    });
  }

  Future insertProcurementRequests(String appid, String monthly_budget_id, String user_id, String item_name, String quantity, String price, String total_price, String status, String division_name) async {
    return _postRequest('insert', {
      'collection': 'procurement_requests',
      'appid': appid,
      'monthly_budget_id': monthly_budget_id,
      'user_id': user_id,
      'item_name': item_name,
      'quantity': quantity,
      'price': price,
      'total_price': total_price,
      'status': status,
      'division_name': division_name
    });
  }

  // =======================================================================
  // 3. FUNGSI SELECT (READ)
  // =======================================================================
  
  Future selectAll(String collection, String appid) async {
    String uri = '${AppConfig.baseUrl}/select_all/token/${AppConfig.token}/project/${AppConfig.project}/collection/$collection/appid/$appid';
    return _getRequest(uri);
  }

  Future selectId(String collection, String appid, String id) async {
    String uri = '${AppConfig.baseUrl}/select_id/token/${AppConfig.token}/project/${AppConfig.project}/collection/$collection/appid/$appid/id/$id';
    return _getRequest(uri);
  }

  Future selectWhere(String collection, String appid, String where_field, String where_value) async {
    // Encode value untuk menangani spasi atau karakter khusus
    final f = Uri.encodeComponent(where_field);
    final v = Uri.encodeComponent(where_value);
    
    String uri = '${AppConfig.baseUrl}/select_where/token/${AppConfig.token}/project/${AppConfig.project}/collection/$collection/appid/$appid/where_field/$f/where_value/$v';
    return _getRequest(uri);
  }

  // =======================================================================
  // 4. FUNGSI UPDATE & DELETE
  // =======================================================================

  Future updateId(String update_field, String update_value, String collection, String appid, String id) async {
    // Safety check: Jangan kirim request jika ID kosong
    if (id.trim().isEmpty) {
      print("DEBUG API: Update dibatalkan. ID Kosong.");
      return false;
    }

    return _putRequest('update_id', {
      'update_field': update_field,
      'update_value': update_value,
      'collection': collection,
      'appid': appid,
      'id': id.trim() // PENTING: Trim spasi
    });
  }
  
  Future removeId(String collection, String appid, String id) async {
     String uri = '${AppConfig.baseUrl}/remove_id/token/${AppConfig.token}/project/${AppConfig.project}/collection/$collection/appid/$appid/id/$id';
     return _deleteRequest(uri);
  }
}