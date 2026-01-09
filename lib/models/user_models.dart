class UsersModel {
  final String? id;
  final String name;
  final String email;
  final String password;
  final String role;
  final String? divisionId;
  final String? divisionName;

  UsersModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.divisionId,
    this.divisionName,
  });

  factory UsersModel.fromJson(Map<String, dynamic> data) {
    return UsersModel(
      id: data['_id']?.toString() ?? data['id']?.toString(),
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      password: data['password']?.toString() ?? '',
      role: data['role']?.toString() ?? 'divisi',
      divisionId: data['division_id']?.toString(),
      divisionName: data['division_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'division_id': divisionId ?? '',
    };
  }

  // Helper methods
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isDivision => role.toLowerCase() == 'divisi';
  
  UsersModel copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? role,
    String? divisionId,
    String? divisionName,
  }) {
    return UsersModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      divisionId: divisionId ?? this.divisionId,
      divisionName: divisionName ?? this.divisionName,
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