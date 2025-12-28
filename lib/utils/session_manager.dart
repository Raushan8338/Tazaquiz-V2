import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazaquiznew/models/login_response_model.dart';

class SessionManager {
  static const _isLoginKey = 'is_logged_in';
  static const _userKey = 'user_data';

  /// Save login session
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoginKey, true);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Get user data
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data == null) return null;
    return UserModel.fromJson(jsonDecode(data));
  }

  /// Check login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoginKey) ?? false;
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
