// ignore_for_file: non_constant_identifier_names

import 'package:http/http.dart' as http;
import 'config.dart'; // PENTING: Pastikan ini mengarah ke file config.dart Anda

class DataService {
  
  // --- FUNGSI INSERT (Menambah Data) ---

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

  // --- FUNGSI SELECT (Mengambil Data) ---
  // Kita hapus parameter 'token' dan 'project' karena sudah diambil dari AppConfig
  
  Future selectAll(String collection, String appid) async {
    String uri = '${AppConfig.baseUrl}/select_all/token/${AppConfig.token}/project/${AppConfig.project}/collection/$collection/appid/$appid';
    return _getRequest(uri);
  }

  Future selectId(String collection, String appid, String id) async {
    String uri = '${AppConfig.baseUrl}/select_id/token/${AppConfig.token}/project/${AppConfig.project}/collection/$collection/appid/$appid/id/$id';
    return _getRequest(uri);
  }

  Future selectWhere(String collection, String appid, String where_field, String where_value) async {
    String uri = '${AppConfig.baseUrl}/select_where/token/${AppConfig.token}/project/${AppConfig.project}/collection/$collection/appid/$appid/where_field/$where_field/where_value/$where_value';
    return _getRequest(uri);
  }

  // --- FUNGSI UPDATE & DELETE (Edit & Hapus) ---

  Future updateId(String update_field, String update_value, String collection, String appid, String id) async {
    return _putRequest('update_id', {
      'update_field': update_field,
      'update_value': update_value,
      'collection': collection,
      'appid': appid,
      'id': id
    });
  }
  
  Future removeId(String collection, String appid, String id) async {
     String uri = '${AppConfig.baseUrl}/remove_id/token/${AppConfig.token}/project/${AppConfig.project}/collection/$collection/appid/$appid/id/$id';
     return _deleteRequest(uri);
  }

  // --- HELPER FUNCTIONS (Supaya kodingan rapi) ---

  Future<String> _postRequest(String endpoint, Map<String, String> body) async {
    String uri = '${AppConfig.baseUrl}/$endpoint/';
    
    // Otomatis masukkan Token & Project ID ke setiap request
    body['token'] = AppConfig.token;
    body['project'] = AppConfig.project;

    try {
      final response = await http.post(Uri.parse(uri), body: body);
      if (response.statusCode == 200) {
        return response.body;
      } else {
        return '{"error": "HTTP ${response.statusCode}: ${response.body}"}';
      }
    } catch (e) {
      return '{"error": "Exception: $e"}';
    }
  }

  Future<String> _getRequest(String uri) async {
    try {
      final response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        return '[]';
      }
    } catch (e) {
      return '[]';
    }
  }

  Future<bool> _putRequest(String endpoint, Map<String, String> body) async {
    String uri = '${AppConfig.baseUrl}/$endpoint/';
    body['token'] = AppConfig.token;
    body['project'] = AppConfig.project;

    try {
      final response = await http.put(Uri.parse(uri), body: body);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _deleteRequest(String uri) async {
    try {
      final response = await http.delete(Uri.parse(uri));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}