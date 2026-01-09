import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserSession {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? divisionId;
  final String? divisionName;

  UserSession({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.divisionId,
    this.divisionName,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isDivision => role.toLowerCase() == 'divisi';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'divisionId': divisionId,
      'divisionName': divisionName,
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'].toString(),
      name: json['name'],
      email: json['email'],
      role: json['role'],
      divisionId: json['divisionId']?.toString(),
      divisionName: json['divisionName'],
    );
  }
}

class SessionManager {
  static const String _keyUser = 'user_session';
  static const String _keyIsLoggedIn = 'is_logged_in';

  // Singleton pattern
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  UserSession? _currentUser;

  UserSession? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Save session
  Future<bool> saveSession(UserSession user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, json.encode(user.toJson()));
      await prefs.setBool(_keyIsLoggedIn, true);
      _currentUser = user;
      return true;
    } catch (e) {
      print('Error saving session: $e');
      return false;
    }
  }

  // Load session
  Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      
      if (!isLoggedIn) return false;

      final userJson = prefs.getString(_keyUser);
      if (userJson == null) return false;

      _currentUser = UserSession.fromJson(json.decode(userJson));
      return true;
    } catch (e) {
      print('Error loading session: $e');
      return false;
    }
  }

  // Clear session (Logout)
  Future<bool> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUser);
      await prefs.setBool(_keyIsLoggedIn, false);
      _currentUser = null;
      return true;
    } catch (e) {
      print('Error clearing session: $e');
      return false;
    }
  }

  // Update session (jika ada perubahan data user)
  Future<bool> updateSession(UserSession user) async {
    return await saveSession(user);
  }

  // Check if session is valid
  Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      return isLoggedIn && _currentUser != null;
    } catch (e) {
      return false;
    }
  }
}