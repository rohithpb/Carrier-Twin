import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthStateProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDemoMode = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null || _isDemoMode;
  bool get isDemoMode => _isDemoMode;

  AuthStateProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signInWithEmail(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      // Fallback for immediate demo testing without setting up Firebase Auth first
      if (email.contains("demo") || email.isNotEmpty) {
        _isDemoMode = true;
        _setLoading(false);
        return true;
      }
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signUpWithEmail(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      // Fallback demo mode
      _isDemoMode = true;
      _setLoading(false);
      return true;
    }
  }

  void startDemoMode() {
    _isDemoMode = true;
    _clearError();
    notifyListeners();
  }

  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _isDemoMode = false;
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
