import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  AuthStatus _status = AuthStatus.loading;
  User? _user;
  String? _token;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      print('AuthProvider: Starting initialization...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);

      if (token != null) {
        print('AuthProvider: Found saved token, verifying...');
        _token = token;
        _apiService.setToken(token);

        // Verify token by fetching user profile
        await _fetchUserProfile();
      } else {
        print('AuthProvider: No saved token found');
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      print('AuthProvider: Initialization error: $e');
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      print('AuthProvider: Fetching user profile...');
      final response = await _apiService.getProfile();
      _user = User.fromJson(response['user']);
      _setStatus(AuthStatus.authenticated);
      print('AuthProvider: Authentication successful');
    } catch (e) {
      print('AuthProvider: Profile fetch failed: $e');
      // Token is invalid, clear it and set status to unauthenticated
      _token = null;
      _user = null;
      _apiService.setToken('');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      print('AuthProvider: Attempting login for $email');
      _setError(null);
      final response = await _apiService.login(email, password);

      _token = response['token'];
      _user = User.fromJson(response['user']);

      // Ensure token is saved to SharedPreferences
      if (_token != null) {
        print('AuthProvider: Saving token to SharedPreferences');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, _token!);
      }

      _setStatus(AuthStatus.authenticated);
      print('AuthProvider: Login successful');
      return true;
    } catch (e) {
      print('AuthProvider: Login failed: $e');
      _setError(e.toString());
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    try {
      _setError(null);
      final response = await _apiService.register(userData);

      _token = response['token'];
      _user = User.fromJson(response['user']);

      // Ensure token is saved to SharedPreferences
      if (_token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, _token!);
      }

      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    try {
      _setError(null);
      final response = await _apiService.updateProfile(userData);
      _user = User.fromJson(response['user']);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);

      _token = null;
      _user = null;
      _apiService.setToken('');

      _setStatus(AuthStatus.unauthenticated);
    } catch (e) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  void _setStatus(AuthStatus status) {
    print('AuthProvider: Status changed to $status');
    _status = status;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }
}
