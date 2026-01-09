class UsersModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role;
  final String division_id;
  final String division_name;

  UsersModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.division_id,
    required this.division_name,
  });

  factory UsersModel.fromJson(Map<String, dynamic> data) {
    return UsersModel(
      id: data['id'] ?? data['_id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      role: data['role'] ?? 'user',
      division_id: data['division_id'] ?? '',
      division_name: data['division_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'division_id': division_id,
      'division_name': division_name,
    };
  }

  // Helper methods
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isUser => role.toLowerCase() == 'user';
  
  UsersModel copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? role,
    String? division_id,
    String? division_name,
  }) {
    return UsersModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      division_id: division_id ?? this.division_id,
      division_name: division_name ?? this.division_name,
    );
  }
}

// ==================== HELPER FUNCTION ====================
/// Safely parse list dari JSON response
List<T> parseListFromJson<T>(
  dynamic jsonData,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (jsonData == null) return [];
  
  if (jsonData is List) {
    return jsonData
        .where((item) => item != null)
        .map((item) {
          try {
            if (item is Map<String, dynamic>) {
              return fromJson(item);
            } else if (item is Map) {
              return fromJson(Map<String, dynamic>.from(item));
            }
          } catch (e) {
            print('Error parsing item: $e');
          }
          return null;
        })
        .whereType<T>()
        .toList();
  }
  
  return [];
}

/// Safely parse single object dari JSON response
T? parseSingleFromJson<T>(
  dynamic jsonData,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (jsonData == null) return null;
  
  try {
    if (jsonData is Map<String, dynamic>) {
      return fromJson(jsonData);
    } else if (jsonData is Map) {
      return fromJson(Map<String, dynamic>.from(jsonData));
    } else if (jsonData is List && jsonData.isNotEmpty) {
      final firstItem = jsonData[0];
      if (firstItem is Map<String, dynamic>) {
        return fromJson(firstItem);
      } else if (firstItem is Map) {
        return fromJson(Map<String, dynamic>.from(firstItem));
      }
    }
  } catch (e) {
    print('Error parsing single object: $e');
  }
  
  return null;
}