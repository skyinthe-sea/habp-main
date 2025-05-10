import 'package:shared_preferences/shared_preferences.dart';

/// Authentication service to manage user session
class AuthService {
  static const String _userIdKey = 'user_id';
  static const int _defaultUserId = 1; // Default user ID for backward compatibility
  
  int? _currentUserId;
  
  /// Initialize the auth service
  Future<AuthService> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt(_userIdKey) ?? _defaultUserId;
    return this;
  }
  
  /// Get the current user ID
  int get currentUserId => _currentUserId ?? _defaultUserId;
  
  /// Set the current user ID
  Future<void> setUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    _currentUserId = userId;
  }
  
  /// Reset the user ID to default
  Future<void> resetUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    _currentUserId = _defaultUserId;
  }
}
