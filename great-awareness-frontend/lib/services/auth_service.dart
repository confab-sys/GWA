import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  
  User? get currentUser => _currentUser;
  
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get canCreateContent => _currentUser?.canPost ?? false;
  
  AuthService() {
    _loadUserFromStorage();
  }
  
  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      final token = prefs.getString('auth_token');
      
      if (userData != null && token != null && token.isNotEmpty) {
        // Optionally validate token expiration or format
        if (_isTokenValid(token)) {
          final userJson = json.decode(userData);
          _currentUser = User.fromJson(userJson, token: token);
          notifyListeners();
        } else {
          // Token is invalid, clear stored data
          await _clearUserFromStorage();
        }
      }
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
      await _clearUserFromStorage();
    }
  }
  
  bool _isTokenValid(String token) {
    // Basic token validation - you can enhance this based on your token format
    // For now, just check if token exists and has minimum length
    return token.length > 10;
  }
  
  // Method to check if user should stay authenticated
  Future<bool> checkAuthentication() async {
    if (_currentUser == null) {
      await _loadUserFromStorage();
    }
    return isAuthenticated;
  }
  
  Future<void> login(User user) async {
    _currentUser = user;
    await _saveUserToStorage(user);
    notifyListeners();
  }
  
  Future<void> logout() async {
    _currentUser = null;
    await _clearUserFromStorage();
    notifyListeners();
  }
  
  Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode({
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'first_name': user.firstName,
        'last_name': user.lastName,
        'phone_number': user.phoneNumber,
        'county': user.county,
        'role': user.role,
      }));
      await prefs.setString('auth_token', user.token ?? '');
    } catch (e) {
      debugPrint('Error saving user to storage: $e');
    }
  }
  
  Future<void> _clearUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('auth_token');
    } catch (e) {
      debugPrint('Error clearing user from storage: $e');
    }
  }
  
  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
  
  // Mock function to simulate admin access for testing
  void mockAdminLogin() {
    _currentUser = User(
      id: 'admin_001',
      email: 'admin@greatawareness.com',
      name: 'Admin User',
      token: 'mock_admin_token',
      role: 'admin',
    );
    notifyListeners();
  }
  
  // Mock function to simulate regular user login for testing
  void mockUserLogin() {
    _currentUser = User(
      id: 'user_001',
      email: 'user@example.com',
      name: 'Regular User',
      token: 'mock_user_token',
      role: 'user',
    );
    notifyListeners();
  }
}