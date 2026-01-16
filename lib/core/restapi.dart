// ignore_for_file: prefer_interpolation_to_compose_strings, non_constant_identifier_names

import 'dart:convert';
import 'package:http/http.dart' as http;

class DataService {
  Future insertDivisions(String appid, String name, String code) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': '690e9167fcee2015d33ec941',
          'project': 'procumon',
          'collection': 'divisions',
          'appid': appid,
          'name': name,
          'code': code,
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertUsers(
    String appid,
    String name,
    String email,
    String password,
    String role,
    String division_id,
    String phone,
  ) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': '690e9167fcee2015d33ec941',
          'project': 'procumon',
          'collection': 'users',
          'appid': appid,
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'division_id': division_id,
          'phone': phone,
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertFiscalYears(String appid, String year, String status) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': '690e9167fcee2015d33ec941',
          'project': 'procumon',
          'collection': 'fiscal_years',
          'appid': appid,
          'year': year,
          'status': status,
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertMonthlyBudgets(
    String appid,
    String fiscal_year_id,
    String month_name,
    String month_index,
    String total_revenue,
    String total_expense,
    String division_id,
  ) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': '690e9167fcee2015d33ec941',
          'project': 'procumon',
          'collection': 'monthly_budgets',
          'appid': appid,
          'fiscal_year_id': fiscal_year_id,
          'month_name': month_name,
          'month_index': month_index,
          'total_revenue': total_revenue,
          'total_expense': total_expense,
          'division_id': division_id,
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertDivisionBudgets(
    String appid,
    String division_name,
    String allocated_budget,
    String month_name,
    String year,
  ) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': '690e9167fcee2015d33ec941',
          'project': 'procumon',
          'collection': 'division_budgets',
          'appid': appid,
          'division_name': division_name,
          'allocated_budget': allocated_budget,
          'month_name': month_name,
          'year': year,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        return '[]';
      }
    } catch (e) {
      return '[]';
    }
  }

  Future insertProcurementRequests(
    String appid,
    String monthly_budget_id,
    String user_id,
    String item_name,
    String quantity,
    String price,
    String total_price,
    String status,
    String division_name,
    String date,
    String month_name,
    String imange_path,
  ) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': '690e9167fcee2015d33ec941',
          'project': 'procumon',
          'collection': 'procurement_requests',
          'appid': appid,
          'monthly_budget_id': monthly_budget_id,
          'user_id': user_id,
          'item_name': item_name,
          'quantity': quantity,
          'price': price,
          'total_price': total_price,
          'status': status,
          'division_name': division_name,
          'date': date,
          'month_name': month_name,
          'imange_path': imange_path,
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  // Method baru dengan rejection_reason untuk update status
  Future insertProcurementRequestsWithReason(
    String appid,
    String monthly_budget_id,
    String user_id,
    String item_name,
    String quantity,
    String price,
    String total_price,
    String status,
    String division_name,
    String date,
    String month_name,
    String imange_path,
    String rejection_reason,
  ) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': '690e9167fcee2015d33ec941',
          'project': 'procumon',
          'collection': 'procurement_requests',
          'appid': appid,
          'monthly_budget_id': monthly_budget_id,
          'user_id': user_id,
          'item_name': item_name,
          'quantity': quantity,
          'price': price,
          'total_price': total_price,
          'status': status,
          'division_name': division_name,
          'date': date,
          'month_name': month_name,
          'imange_path': imange_path,
          'rejection_reason': rejection_reason,
        },
      );

      print('insertProcurementRequestsWithReason response: ${response.body}');

      if (response.statusCode == 200) {
        return response.body;
      } else {
        return '[]';
      }
    } catch (e) {
      print('insertProcurementRequestsWithReason error: $e');
      return '[]';
    }
  }

  Future selectAll(
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_all/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectId(
    String token,
    String project,
    String collection,
    String appid,
    String id,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_id/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/id/' +
        id;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectWhere(
    String token,
    String project,
    String collection,
    String appid,
    String where_field,
    String where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/where_field/' +
        where_field +
        '/where_value/' +
        where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectOrWhere(
    String token,
    String project,
    String collection,
    String appid,
    String or_where_field,
    String or_where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_or_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/or_where_field/' +
        or_where_field +
        '/or_where_value/' +
        or_where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectWhereLike(
    String token,
    String project,
    String collection,
    String appid,
    String wlike_field,
    String wlike_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_where_like/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wlike_field/' +
        wlike_field +
        '/wlike_value/' +
        wlike_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectWhereIn(
    String token,
    String project,
    String collection,
    String appid,
    String win_field,
    String win_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_where_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/win_field/' +
        win_field +
        '/win_value/' +
        win_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectWhereNotIn(
    String token,
    String project,
    String collection,
    String appid,
    String wnotin_field,
    String wnotin_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_where_not_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wnotin_field/' +
        wnotin_field +
        '/wnotin_value/' +
        wnotin_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future removeAll(
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_all/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeId(
    String token,
    String project,
    String collection,
    String appid,
    String id,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_id/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/id/' +
        id;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeWhere(
    String token,
    String project,
    String collection,
    String appid,
    String where_field,
    String where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/where_field/' +
        where_field +
        '/where_value/' +
        where_value;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeOrWhere(
    String token,
    String project,
    String collection,
    String appid,
    String or_where_field,
    String or_where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_or_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/or_where_field/' +
        or_where_field +
        '/or_where_value/' +
        or_where_value;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeWhereLike(
    String token,
    String project,
    String collection,
    String appid,
    String wlike_field,
    String wlike_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_where_like/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wlike_field/' +
        wlike_field +
        '/wlike_value/' +
        wlike_value;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeWhereIn(
    String token,
    String project,
    String collection,
    String appid,
    String win_field,
    String win_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_where_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/win_field/' +
        win_field +
        '/win_value/' +
        win_value;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeWhereNotIn(
    String token,
    String project,
    String collection,
    String appid,
    String wnotin_field,
    String wnotin_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_where_not_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wnotin_field/' +
        wnotin_field +
        '/wnotin_value/' +
        wnotin_value;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future updateAll(
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_all/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateId(
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
    String id,
  ) async {
    String uri = 'https://api.247go.app/v5/update_id/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
          'id': id,
        },
      );

      print('updateId response status: ${response.statusCode}');
      print('updateId response body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if API returned success
        try {
          final jsonResp = json.decode(response.body);
          print('updateId parsed status: ${jsonResp['status']}');
          // GoCloud return status as integer 1 for success
          if (jsonResp['status'] == 1 || jsonResp['status'] == '1') {
            print('updateId success!');
            return true;
          } else {
            print('updateId API error: ${jsonResp['message']}');
            return false;
          }
        } catch (e) {
          print('updateId parse error: $e');
          return true; // Assume success if can't parse but status 200
        }
      } else {
        print('updateId HTTP error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('updateId exception: $e');
      return false;
    }
  }

  Future updateWhere(
    String where_field,
    String where_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_where/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'where_field': where_field,
          'where_value': where_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateOrWhere(
    String or_where_field,
    String or_where_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_or_where/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'or_where_field': or_where_field,
          'or_where_value': or_where_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateWhereLike(
    String wlike_field,
    String wlike_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_where_like/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'wlike_field': wlike_field,
          'wlike_value': wlike_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateWhereIn(
    String win_field,
    String win_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_where_in/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'win_field': win_field,
          'win_value': win_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateWhereNotIn(
    String wnotin_field,
    String wnotin_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_where_not_in/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'wnotin_field': wnotin_field,
          'wnotin_value': wnotin_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future firstAll(
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_all/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstWhere(
    String token,
    String project,
    String collection,
    String appid,
    String where_field,
    String where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/where_field/' +
        where_field +
        '/where_value/' +
        where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstOrWhere(
    String token,
    String project,
    String collection,
    String appid,
    String or_where_field,
    String or_where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_or_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/or_where_field/' +
        or_where_field +
        '/or_where_value/' +
        or_where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstWhereLike(
    String token,
    String project,
    String collection,
    String appid,
    String wlike_field,
    String wlike_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_where_like/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wlike_field/' +
        wlike_field +
        '/wlike_value/' +
        wlike_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstWhereIn(
    String token,
    String project,
    String collection,
    String appid,
    String win_field,
    String win_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_where_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/win_field/' +
        win_field +
        '/win_value/' +
        win_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstWhereNotIn(
    String token,
    String project,
    String collection,
    String appid,
    String wnotin_field,
    String wnotin_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_where_not_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wnotin_field/' +
        wnotin_field +
        '/wnotin_value/' +
        wnotin_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastAll(
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri =
        'https://api.247go.app/v5/last_all/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastWhere(
    String token,
    String project,
    String collection,
    String appid,
    String where_field,
    String where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/last_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/where_field/' +
        where_field +
        '/where_value/' +
        where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastOrWhere(
    String token,
    String project,
    String collection,
    String appid,
    String or_where_field,
    String or_where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/last_or_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/or_where_field/' +
        or_where_field +
        '/or_where_value/' +
        or_where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastWhereLike(
    String token,
    String project,
    String collection,
    String appid,
    String wlike_field,
    String wlike_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/last_where_like/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wlike_field/' +
        wlike_field +
        '/wlike_value/' +
        wlike_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastWhereIn(
    String token,
    String project,
    String collection,
    String appid,
    String win_field,
    String win_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/last_where_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/win_field/' +
        win_field +
        '/win_value/' +
        win_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastWhereNotIn(
    String token,
    String project,
    String collection,
    String appid,
    String wnotin_field,
    String wnotin_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/last_where_not_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wnotin_field/' +
        wnotin_field +
        '/wnotin_value/' +
        wnotin_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomAll(
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri =
        'https://api.247go.app/v5/random_all/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomWhere(
    String token,
    String project,
    String collection,
    String appid,
    String where_field,
    String where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/random_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/where_field/' +
        where_field +
        '/where_value/' +
        where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomOrWhere(
    String token,
    String project,
    String collection,
    String appid,
    String or_where_field,
    String or_where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/random_or_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/or_where_field/' +
        or_where_field +
        '/or_where_value/' +
        or_where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomWhereLike(
    String token,
    String project,
    String collection,
    String appid,
    String wlike_field,
    String wlike_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/random_where_like/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wlike_field/' +
        wlike_field +
        '/wlike_value/' +
        wlike_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomWhereIn(
    String token,
    String project,
    String collection,
    String appid,
    String win_field,
    String win_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/random_where_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/win_field/' +
        win_field +
        '/win_value/' +
        win_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomWhereNotIn(
    String token,
    String project,
    String collection,
    String appid,
    String wnotin_field,
    String wnotin_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/random_where_not_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wnotin_field/' +
        wnotin_field +
        '/wnotin_value/' +
        wnotin_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }
}
