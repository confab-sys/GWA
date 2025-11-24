import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  
  User? get currentUser => _currentUser;
  
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get canCreateContent => _currentUser?.canPost ?? false;
  
  void login(User user) {
    _currentUser = user;
    notifyListeners();
  }
  
  void logout() {
    _currentUser = null;
    notifyListeners();
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